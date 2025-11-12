#if 1

#include <peglib.h>
#include <iostream>
#include <string>
#include <vector>

static const char* grammar = R"(
    %whitespace <- [ \t\r\n]*
    COMMENT      <- ('#' [^\n]* / '//' [^\n]* / '/*' (!'*/' .)* '*/')
    _            <- (%whitespace / COMMENT)*

    Start        <- _ ('Query' _ ':' _)? (ForallQuery / SimpleQuery) _
    ForallQuery  <- 'forall' _ '(' _ TypeVarList _ ')' _ ':' _ QueryCore
    SimpleQuery  <- QueryCore
    QueryCore    <- OptName? _ Params _ '->' _ Type

    OptName      <- Name
    Name         <- '_' / Identifier

    Params       <- '(' _ ArgTypes? _ ')'
    ArgTypes     <- Type (_ ',' _ Type)*

    TypeVarList  <- TypeVar (_ ',' _ TypeVar)*
    TypeVar      <- Identifier _ ':' _ 'TYPE'

    # Тип — как единый токен: получаем исходную подстроку
    Type         <- < CoreType PtrRefSeq? >
    CoreType     <- QualifiedId TemplateArgs?
    QualifiedId  <- Identifier ('::' Identifier)*
    TemplateArgs <- '<' _ Type (_ ',' _ Type)* _ '>'
    PtrRefSeq    <- ('*' / '&' / '&&')*

    Identifier   <- !Keyword [A-Za-z_] [A-Za-z0-9_]*
    Keyword      <- 'forall' / 'TYPE'
)";

int main() {
    peg::parser p(grammar);
    if (!p) { std::cerr << "Bad grammar\n"; return 1; }

    // Query examples
    std::string source = "Query: forall (T : TYPE) : _ (T&, T*) -> T";
    // std::string source = "Query: _ (std::vector<concurent::future<int>>) -> concurent::future<std::vector<int>>";
    // std::string source = "sum(int, long long) -> long long";

    p.enable_ast();
    std::shared_ptr<peg::Ast> ast;
    if (p.parse(source, ast)) {
        ast = p.optimize_ast(ast);
        std::cout << ast_to_s(ast);
        return 0;
    }
    else
    {
        std::cout << "parse error" << std::endl;
    }

    return 0;
}

#else
//
//  indent.cc
//
//  Copyright (c) 2022 Yuji Hirose. All rights reserved.
//  MIT License
//

// Based on https://gist.github.com/dmajda/04002578dd41ae8190fc

#include <cstdlib>
#include <iostream>
#include <peglib.h>

using namespace peg;

int main(void) {
  parser parser(R"(Start <- Statements {}
Statements <- Statement*
Statement <- Samedent (S / I)

S <- 'S' EOS { no_ast_opt }
I <- 'I' EOL Block / 'I' EOS { no_ast_opt }

Block <- Statements {}

~Samedent <- ' '* {}

~EOS <- EOL / EOF
~EOL <- '\n'
~EOF <- !.
  )");

  size_t indent = 0;

  parser["Block"].enter = [&](const Context & /*c*/, const char * /*s*/,
                              size_t /*n*/, std::any & /*dt*/) { indent += 2; };

  parser["Block"].leave = [&](const Context & /*c*/, const char * /*s*/,
                              size_t /*n*/, size_t /*matchlen*/,
                              std::any & /*value*/,
                              std::any & /*dt*/) { indent -= 2; };

  parser["Samedent"].predicate =
      [&](const SemanticValues &vs, const std::any & /*dt*/, std::string &msg) {
        if (indent != vs.sv().size()) {
          msg = "different indent...";
          return false;
        }
        return true;
      };

  parser.enable_ast();

  const auto source = R"(I
  S
  I
    I
      S
      S
    S
  S
)";

  std::shared_ptr<Ast> ast;
  if (parser.parse(source, ast)) {
    ast = parser.optimize_ast(ast);
    std::cout << ast_to_s(ast);
    return 0;
  }

  std::cout << "syntax error..." << std::endl;
  return -1;
}
#endif