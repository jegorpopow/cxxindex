#include <clang/AST/ASTConsumer.h>
#include <clang/AST/ASTContext.h>
#include <clang/AST/Decl.h>
#include <clang/AST/DeclBase.h>
#include <clang/AST/DeclTemplate.h>
#include <clang/AST/RecursiveASTVisitor.h>
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

using namespace clang;
using namespace clang::tooling;

struct quoted_string_view: std::string_view {};

struct type_decl {
  TypeDecl t;
};

struct function_decl {
  quoted_string_view name;
  std::vector<quoted_string_view> arg_types;
  quoted_string_view return_type;
};

struct null_format_parser {
  constexpr auto parse(std::format_parse_context& ctx) { return ctx.begin(); }
};

template<>
struct std::formatter<quoted_string_view>: null_format_parser {
  constexpr auto format(quoted_string_view& t, format_context& ctx) {
    return format_to(ctx.out(), "\"{}\"", string_view(t));
  }
};

template<>
struct std::formatter<function_decl>: null_format_parser {
  constexpr auto format(function_decl& f, format_context& ctx) {
    return format_to(ctx.out(),
R"(CDecl {{
  name = {},
  ctype = CDeclType {{
    template_args = [],
    arguments = fromList [ {} ],
    result = CTName {}
  }}
}})",
      f.name, 0, f.return_type
    );
  }
};


struct ast_visitor:
  RecursiveASTVisitor<ast_visitor>,
  ASTConsumer
{
  using base_visitor = RecursiveASTVisitor<ast_visitor>;

  CompilerInstance& compiler;

  explicit ast_visitor(CompilerInstance& compiler): compiler(compiler) {}

  void HandleTranslationUnit(ASTContext& c) override {
    TraverseDecl(c.getTranslationUnitDecl());
  }

  bool TraverseFunctionDecl(FunctionDecl* f) {
    if (f->isFirstDecl() && !f->isDependentContext()) {
      std::print("{} {}(",
        f->getReturnType().getAsString(),
        f->getQualifiedNameAsString());
      unsigned n_params = f->getNumParams();
      for (unsigned i = 0; i < n_params; ++i) {
        std::print("{}{}",
          i ? ", " : "",
          f->getParamDecl(i)->getType().getAsString());
      }
      std::println(")");

      {
        /*
        CDecl {
          name = "foo",
          ctype = CDeclType {template_args = [("T",CKType)],
          arguments = fromList [CTVar "T"], result = CTName "int"}, location =
          "here"
        }
        */
      }
    }
    return base_visitor::TraverseFunctionDecl(f);
  }
};

struct action: ASTFrontendAction {
  std::unique_ptr<ASTConsumer>
  CreateASTConsumer(CompilerInstance& compiler, llvm::StringRef) override {
    return std::make_unique<ast_visitor>(compiler);
  }
};

int main(int argc, const char** argv) {
  auto parser = CommonOptionsParser::create(argc, argv, llvm::cl::getGeneralCategory());
  if (!parser) {
    llvm::errs() << parser.takeError();
    return 1;
  }
  ClangTool tool(parser->getCompilations(), parser->getSourcePathList());
  return tool.run(newFrontendActionFactory<action>().get());
}