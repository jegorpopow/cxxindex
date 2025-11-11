# Сборка

Сначала надо собрать LLVM, потом этот тул.

## Сборка LLVM

Можно следовать гайду: [Building LLVM with CMake](https://llvm.org/docs/CMake.html).

Я использовал примерно следующие команды:

```
$ git clone <llvm-project-url> llvm-project
$ cd llvm-project
$ cmake \
  -S llvm -B build -GNinja \
  -DCMAKE_INSTALL_PREFIX="<LLVM-INSTALL-DIR>" \
  -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" \
  -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCLANG_DEFAULT_CXX_STDLIB=libc++ \
  -DLLVM_ENABLE_ASSERTIONS=OFF \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_TARGETS_TO_BUILD=X86 \
  -DLLVM_OPTIMIZED_TABLEGEN=ON \
  -DCLANG_ENABLE_STATIC_ANALYZER=OFF \
  -DBUILD_SHARED_LIBS=ON
```

Сборка LLVM может занять долгое время, особенно на средне-слабых компьютерах.

Обратите внимание на `<LLVM-INSTALL-DIR>` - укажите здесь путь, куда будет устанавливаться LLVM.

После этого можно собрать и установить LLVM:

```
$ cmake --build build
$ cmake --install build
```
## Сборка тула

Нужно пробросить в переменные окружения пути до llvm и clang (где `<LLVM_INSTALL_DIR>` та же, что в предыдущем шаге), после чего использовать cmake-сборку "как обычно":

```shell
$ export LLVM_DIR="<LLVM_INSTALL_DIR>/lib/cmake/llvm/"
$ export Clang_DIR="<LLVM_INSTALL_DIR>/lib/cmake/clang"
$ cmake --preset default
$ cmake --build build --config Debug # для Debug-конфигурации тулы
#    или
$ cmake --build build --config Debug # для Release-конфигурации
```