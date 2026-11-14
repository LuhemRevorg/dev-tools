#include <filesystem>
#include <iostream>
#include <queue>
#include <string>
#include <fstream>
#include <system_error>

namespace fs = std::filesystem;
std::string STORE = std::string(std::getenv("HOME")) + "/.cache/cdr/map";

// Hidden directories, dependency trees and ~/Library are huge and rarely the
// target. They can still match by name, they just aren't searched inside.
static bool should_descend(const std::string& name) {
	return name[0] != '.' && name != "node_modules" && name != "Library" && name != ".cache";
}


std::string check_file(const std::string &curr_root, const std::string &target) {
	
	std::ifstream f(STORE);
	
	if (!f.is_open()) throw "Unable to open storage file";

	std::string root, name, result;

	while (std::getline(f, root, '\t') && std::getline(f, name, '\t') && std::getline(f, result))
		if (curr_root == root && target == name) return result;
	
	throw "No Match run bfs";
}

std::string pathfinder(const std::string &root, const std::string &target, std::error_code &ec) { // Apex legend btw

	std::queue<fs::path> q;
	q.push(root);

	while (!q.empty()) {
		const fs::path dir = q.front();
		q.pop();

		fs::directory_iterator it(dir, fs::directory_options::skip_permission_denied, ec);
		if (ec) continue; // unreadable: skip it and keep searching

		// increment(ec) turns `it` into the end iterator on failure, ending the loop.
		for (const fs::directory_iterator end; it != end; it.increment(ec)) {
			// symlink_status doesn't follow links, so symlink cycles can't trap us.
			if (!fs::is_directory(it->symlink_status(ec))) continue;

			const std::string name = it->path().filename().string();
			if (name == target) {
				return it->path().string();
			}
			if (should_descend(name)) q.push(it->path());
		}
	}

	throw "Could not find file";
}

// Prints the absolute path of the shallowest directory named argv[1]
int main(int argc, char* argv[]) {

	if (argc==1) {std::cout<< std::getenv("HOME") << "\n"; return 0;}
	if (argc > 3) {
		std::cerr << "usage: cdr <directory-name> [search-root]\n";
		return 2;
	}
	std::error_code ec;
	const std::string target(argv[1]);
	const fs::path root = fs::absolute(argc == 3 ? fs::path(argv[2]) : fs::path("."), ec).lexically_normal();
	if (ec || !fs::is_directory(root, ec)) {
		std::cerr << "cdr: not a directory: " << (argc == 3 ? argv[2] : ".") << "\n";
		return 2;
	}

	try {
		std::cout << check_file(root, target) << std::endl;
	} catch (...) {

		try {
			auto path = pathfinder(root, target, ec);
			// write to file
			std::ofstream outFile(STORE, std::ios::app);
			outFile << root.string() << "\t" << target << "\t" << path << std::endl; 
			std::cout << path << std::endl;
		} catch (...) {				
			std::cerr << "cdr: no directory named '" << target << "' under " << root.string() << "\n";
			return 1;
		}
	}
	return 0;


}
