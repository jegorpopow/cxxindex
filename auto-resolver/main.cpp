#include <clang/Tooling/Tooling.h>
#include <clang/AST/ASTConsumer.h>
#include <clang/AST/RecursiveASTVisitor.h>
#include <vector>
#include <string>
#include <iostream>

// Визитор: собирает тип функции с заданным именем
class FunctionTypeVisitor : public clang::RecursiveASTVisitor<FunctionTypeVisitor> {
public:
    FunctionTypeVisitor(const std::string& targetName, std::string& foundType)
        : targetName(targetName), foundType(foundType) {}

    bool VisitFunctionDecl(clang::FunctionDecl* FD) {
        if (FD->isThisDeclarationADefinition()) {
            std::string funcName = FD->getNameInfo().getName().getAsString();
            if (funcName == targetName) {
                foundType = FD->getReturnType().getAsString();
            }
        }
        return true;
    }
private:
    const std::string& targetName;
    std::string& foundType;
};

class FunctionTypeConsumer : public clang::ASTConsumer {
public:
    FunctionTypeConsumer(const std::string& targetName, std::string& foundType)
        : visitor(targetName, foundType) {}
    void HandleTranslationUnit(clang::ASTContext& Context) override {
        visitor.TraverseDecl(Context.getTranslationUnitDecl());
    }
private:
    FunctionTypeVisitor visitor;
};

class FunctionTypeAction : public clang::ASTFrontendAction {
public:
    FunctionTypeAction(const std::string& targetName, std::string& foundType)
        : targetName(targetName), foundType(foundType) {}
    std::unique_ptr<clang::ASTConsumer> CreateASTConsumer(
        clang::CompilerInstance& CI, llvm::StringRef InFile) override {
        return std::make_unique<FunctionTypeConsumer>(targetName, foundType);
    }
private:
    std::string targetName;
    std::string& foundType;
};



std::string getFunctionReturnType(std::string funcName, std::vector<std::string> paramTypes, std::string translationUnit) {
    std::string foundType;
    std::string code;
    code.append("include \""+translationUnit+"\"\n");
    code.append("auto "+funcName+"(");
    for (auto t: paramTypes)
    {
        code.append(t+"(), ");
    }

    clang::tooling::runToolOnCode(
        std::make_unique<FunctionTypeAction>(funcName, foundType), code);
    return foundType;
}

template <typename T>
T identity(const T& value) {
    return value;
}

int main()
{
    std::string retType = getFunctionReturnType("identity", std::vector<std::string>{"int"}, "/home/jdenv/rep/itmo/cindex/example.h");
    std::cout<<retType;

    return 0;
}
