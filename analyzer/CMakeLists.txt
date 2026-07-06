cmake_minimum_required(VERSION 3.14)
project(MergeLensAnalyzer C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Suppress the FetchContent timestamp warning
if(POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW)
endif()

include(FetchContent)

# 1. Fetch JSON Library
FetchContent_Declare(nlohmann_json
    URL https://github.com/nlohmann/json/releases/download/v3.11.2/json.tar.xz
)
FetchContent_MakeAvailable(nlohmann_json)

# 2. Fetch Tree-sitter Core
FetchContent_Declare(tree_sitter
    URL https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v0.20.8.tar.gz
)
FetchContent_MakeAvailable(tree_sitter)
add_library(ts_core STATIC ${tree_sitter_SOURCE_DIR}/lib/src/lib.c)
target_include_directories(ts_core PRIVATE ${tree_sitter_SOURCE_DIR}/lib/src) # <-- THE FIX: Added internal src folder
target_include_directories(ts_core PUBLIC ${tree_sitter_SOURCE_DIR}/lib/include)

# 3. Fetch Tree-sitter Python
FetchContent_Declare(ts_python
    URL https://github.com/tree-sitter/tree-sitter-python/archive/refs/tags/v0.20.4.tar.gz
)
FetchContent_MakeAvailable(ts_python)

# 4. Fetch Tree-sitter C++
FetchContent_Declare(ts_cpp
    URL https://github.com/tree-sitter/tree-sitter-cpp/archive/refs/tags/v0.20.3.tar.gz
)
FetchContent_MakeAvailable(ts_cpp)

# Define our executable
add_executable(mergelens-analyzer 
    src/main.cpp 
    src/parser.cpp
    ${ts_python_SOURCE_DIR}/src/parser.c
    ${ts_python_SOURCE_DIR}/src/scanner.c
    ${ts_cpp_SOURCE_DIR}/src/parser.c
    ${ts_cpp_SOURCE_DIR}/src/scanner.c
)

# Link libraries and includes
target_include_directories(mergelens-analyzer PRIVATE include)
target_include_directories(mergelens-analyzer PRIVATE ${ts_python_SOURCE_DIR}/src)
target_include_directories(mergelens-analyzer PRIVATE ${ts_cpp_SOURCE_DIR}/src)

target_link_libraries(mergelens-analyzer PRIVATE 
    ts_core 
    nlohmann_json::nlohmann_json
)