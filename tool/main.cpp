#include <clang/AST/Decl.h>
#include <clang/ASTMatchers/ASTMatchers.h>
#include <clang/ASTMatchers/ASTMatchFinder.h>
#include <clang/Frontend/FrontendActions.h>
#include <clang/Tooling/CommonOptionsParser.h>
#include <clang/Tooling/Tooling.h>
#include <print>
#include <llvm/Support/CommandLine.h>
#include <string_view>

using namespace clang::tooling;
using namespace clang::ast_matchers;
using namespace llvm;

int main(int argc, const char** argv) {
  auto parser = CommonOptionsParser::create(argc, argv, cl::getGeneralCategory());
  if (!parser) {
    llvm::errs() << parser.takeError();
    return 1;
  }
  ClangTool tool(parser->getCompilations(), parser->getSourcePathList());

  struct: MatchFinder::MatchCallback {
    void run(const MatchFinder::MatchResult& m) override {
      auto* node = m.Nodes.getNodeAs<clang::FunctionDecl>("f");
      std::string_view name = node->getName();
      std::println("{}", name);
    }
  } sink;
  MatchFinder finder;
  finder.addMatcher(functionDecl().bind("f"), &sink);

  return tool.run(newFrontendActionFactory(&finder).get());
}