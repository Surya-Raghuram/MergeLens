#include "parser.hpp"
#include <iostream>

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <filepath>" << std::endl;
        return 1;
    }

    try {
        CodeParser parser(argv[1]);
        json result = parser.parse();
        
        // Print strictly JSON to stdout so Python can read it cleanly
        std::cout << result.dump(4) << std::endl;
    } catch (const std::exception& e) {
        // Output errors as JSON to prevent Python JSONDecodeErrors
        json error_json = {{"error", e.what()}};
        std::cout << error_json.dump() << std::endl;
        return 1;
    }

    return 0;
}