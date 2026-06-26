#pragma once

#include <filesystem>
#include <string>

inline std::string meshPath(const char* filename)
{
    return (std::filesystem::path(GMSHPARSER_MESH_DIR) / filename).string();
}
