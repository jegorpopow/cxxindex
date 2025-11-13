#include <clang/AST/ASTConsumer.h>
#include <clang/AST/ASTContext.h>
#include <clang/AST/Decl.h>
#include <clang/AST/DeclBase.h>
#include <clang/AST/DeclTemplate.h>
#include <clang/AST/RecursiveASTVisitor.h>
#include <clang/AST/Type.h>
#include <clang/Basic/SourceLocation.h>
#include <clang/Basic/SourceManager.h>
#include <clang/Frontend/CompilerInstance.h>
#include <clang/Frontend/FrontendAction.h>
#include <clang/Tooling/CommonOptionsParser.h>
#include <clang/Tooling/Tooling.h>
#include <clang/Sema/Sema.h>
#include <format>
#include <llvm/ADT/StringRef.h>
#include <llvm/Support/Casting.h>
#include <llvm/Support/CommandLine.h>
#include <llvm/Support/raw_ostream.h>
#include <memory>
#include <print>
#include <ranges>

namespace hs {

struct quoted_string_view: std::string_view {};

struct type: clang::QualType {
  using clang::QualType::QualType, clang::QualType::operator=;
  type(clang::QualType t): clang::QualType(t) {}
};

} // namespace hs

struct null_format_parser {
  constexpr static auto parse(std::format_parse_context& ctx) { return ctx.begin(); }
};

template<>
struct std::formatter<hs::quoted_string_view>: null_format_parser {
  static auto format(hs::quoted_string_view t, auto& ctx) {
    auto put = [&](char c) { *ctx.out()++ = c; };
    put('"');
    for (char c: t) {
      if (c == '\\' || c == '"') { put('\\'); }
      put(c);
    }
    put('"');
    return ctx.out();
  }
};

template<>
struct std::formatter<hs::type>: null_format_parser {
  static auto format(hs::type t, auto& ctx) {
    int parens = 0;
    auto wrap = [&](std::string_view s) {
      ++parens;
      format_to(ctx.out(), "{} (", s);
    };

    if (t->isLValueReferenceType()) { wrap("CTLRef"); }
    if (t->isRValueReferenceType()) { wrap("CTRRef"); }
    t = t.getNonReferenceType();

  peel:
    if (t.isLocalConstQualified()) { wrap("CTConst"); }
    if (t.isLocalVolatileQualified()) { wrap("CTVolatile"); }
    t.removeLocalFastQualifiers();

    if (t->isPointerType()) {
      wrap("CTPointer");
      t = t->getPointeeType();
      goto peel;
    }

    // Don't handle template type applications, just pass them as qualified name
    format_to(ctx.out(), "CTName {}", hs::quoted_string_view(t.getAsString()));
    while (parens-- > 0) { *ctx.out()++ = ')'; }
    return ctx.out();
  }
};

template<typename Range>
  requires requires (Range range) {
    { *std::begin(range) } -> std::formattable<char>;
  }
struct std::formatter<Range>: null_format_parser {
  static auto format(const Range& range, format_context& ctx) {
    auto put = [&](char c) { *ctx.out()++ = c; };
    bool first = true;
    put('[');
    for (auto&& elem: range) {
      if (!first) {
        put(',');
        put(' ');
      } else {
        first = false;
      }
      format_to(ctx.out(), "{}", elem);
    }
    put(']');
    return ctx.out();
  }
};

struct ast_visitor:
  clang::RecursiveASTVisitor<ast_visitor>,
  clang::ASTConsumer
{
  using base_visitor = RecursiveASTVisitor<ast_visitor>;

  clang::CompilerInstance& compiler;

  explicit ast_visitor(clang::CompilerInstance& compiler): compiler(compiler) {}

  void HandleTranslationUnit(clang::ASTContext& c) override {
    TraverseDecl(c.getTranslationUnitDecl());
  }

  bool TraverseFunctionDecl(clang::FunctionDecl* f) {
    if (f->isFirstDecl() && !f->isDependentContext()) {
      using namespace std::views;
      std::println(
      "CDecl {{"
        "name = {},"
        "ctype = CDeclType {{"
          "template_args = [], arguments = {}, result = {}"
        "}},"
        "location = {}"
      "}}",
        hs::quoted_string_view(f->getQualifiedNameAsString()),
        iota(0, int(f->getNumParams())) | transform([&](int i) {
          return hs::type(f->getParamDecl(i)->getType().getCanonicalType());
        }),
        hs::type(f->getReturnType().getCanonicalType()),
        hs::quoted_string_view(f->getLocation().printToString(compiler.getSourceManager())));
    }
    return base_visitor::TraverseFunctionDecl(f);
  }
};

struct action: clang::ASTFrontendAction {
  std::unique_ptr<clang::ASTConsumer>
  CreateASTConsumer(clang::CompilerInstance& compiler, llvm::StringRef) override {
    return std::make_unique<ast_visitor>(compiler);
  }
};

int main(int argc, const char** argv) {
  using namespace clang::tooling;
  auto parser = CommonOptionsParser::create(argc, argv, llvm::cl::getGeneralCategory());
  if (!parser) {
    llvm::errs() << parser.takeError();
    return 1;
  }
  ClangTool tool(parser->getCompilations(), parser->getSourcePathList());
  return tool.run(newFrontendActionFactory<action>().get());
}