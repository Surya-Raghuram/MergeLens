#include "parser.hpp"
#include <fstream>
#include <sstream>
#include <iostream>
#include <tree_sitter/api.h>

// Extern declarations for the Tree-sitter language grammars
extern "C" const TSLanguage *tree_sitter_python();
extern "C" const TSLanguage *tree_sitter_cpp();

CodeParser::CodeParser(const std::string& filepath) : filepath_(filepath) {}

std::string CodeParser::read_file(const std::string& path) {
    std::ifstream file(path);
    if (!file.is_open()) {
        throw std::runtime_error("Could not open file: " + path);
    }
    std::stringstream buffer;
    buffer << file.rdbuf();
    return buffer.str();
}

std::string CodeParser::get_node_text(void* node_ptr, const std::string& source_code) {
    TSNode node = *static_cast<TSNode*>(node_ptr);
    uint32_t start = ts_node_start_byte(node);
    uint32_t end = ts_node_end_byte(node);
    if (start >= source_code.length() || end > source_code.length() || start >= end) {
        return "";
    }
    return source_code.substr(start, end - start);
}

void CodeParser::extract_structure(json& output, void* node_ptr, const std::string& source_code) {
    TSNode node = *static_cast<TSNode*>(node_ptr);
    const char* type = ts_node_type(node);
    std::string node_type(type);

    // Look for definitions (this covers both Python and C++ AST structures broadly)
    if (node_type == "function_definition" || node_type == "class_definition") {
        // Attempt to find the name of the function/class
        TSNode name_node = ts_node_child_by_field_name(node, "name", 4);
        std::string name = "anonymous";
        
        if (!ts_node_is_null(name_node)) {
            name = get_node_text(&name_node, source_code);
        }

        uint32_t start_line = ts_node_start_point(node).row + 1;
        uint32_t end_line = ts_node_end_point(node).row + 1;

        json item = {
            {"name", name},
            {"type", node_type == "class_definition" ? "class" : "function"},
            {"start_line", start_line},
            {"end_line", end_line}
        };
        
        output["structure"].push_back(item);
    }

    // Recursively walk the AST
    uint32_t child_count = ts_node_child_count(node);
    for (uint32_t i = 0; i < child_count; i++) {
        TSNode child = ts_node_child(node, i);
        extract_structure(output, &child, source_code);
    }
}

json CodeParser::parse() {
    std::string source_code = read_file(filepath_);
    
    TSParser *parser = ts_parser_new();
    std::string ext = filepath_.substr(filepath_.find_last_of(".") + 1);

    // Route to correct grammar based on extension
    if (ext == "py") {
        ts_parser_set_language(parser, tree_sitter_python());
    } else if (ext == "cpp" || ext == "hpp" || ext == "cc" || ext == "h") {
        ts_parser_set_language(parser, tree_sitter_cpp());
    } else {
        ts_parser_delete(parser);
        return {{"error", "Unsupported language extension: " + ext}};
    }

    TSTree *tree = ts_parser_parse_string(parser, NULL, source_code.c_str(), source_code.length());
    if (!tree) {
        ts_parser_delete(parser);
        throw std::runtime_error("Failed to parse source code.");
    }

    TSNode root_node = ts_tree_root_node(tree);

    json output;
    output["file"] = filepath_;
    output["language"] = ext;
    output["structure"] = json::array();

    extract_structure(output, &root_node, source_code);

    ts_tree_delete(tree);
    ts_parser_delete(parser);

    return output;
}