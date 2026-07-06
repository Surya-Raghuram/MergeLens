#pragma once

#include <string>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

class CodeParser {
public:
    CodeParser(const std::string& filepath);
    json parse();

private:
    std::string filepath_;

    std::string read_file(const std::string& path);
    std::string get_node_text(void* node_ptr, const std::string& source_code);
    void extract_structure(json& output,
                           void* node_ptr,
                           const std::string& source_code);
};