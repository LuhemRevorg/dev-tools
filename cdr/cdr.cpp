#include <filesystem>
#include <iostream>
#include <queue>
#include <string>
#include <fstream>
#include <system_error>
#include <set>
#include <vector>

namespace fs = std::filesystem;
std::string STORE = std::string(std::getenv("HOME")) + "/.cache/cdr/map";

// Hidden directories, dependency trees and ~/Library are huge and rarely the
// target. They can still match by name, they just aren't searched inside.
static bool should_descend(const std::string& name) {
	return name[0] != '.' && name != "node_modules" && name != "Library" && name != ".cache";
}


// Looks up (curr_root, target) in the cache. Along the way it drops lines that
// are blank or malformed, duplicated, or point at a directory that no longer
// exists, and rewrites the file if it dropped anything.
std::string check_file(const std::string &curr_root, const std::string &target) {

	std::ifstream f(STORE);

	if (!f.is_open()) throw "Unable to open storage file";

	std::vector<std::string> keep;
	std::set<std::string> seen;
	std::string line, hit;
	bool dirty = false;

	// Read whole lines and split them, so a blank or broken line can't run
	// into the next entry (getline(f, x, '\t') reads straight past '\n').
	while (std::getline(f, line)) {
		const size_t a = line.find('\t');
		const size_t b = (a == std::string::npos) ? a : line.find('\t', a + 1);
		if (b == std::string::npos) { dirty = true; continue; }       // blank/malformed
		if (!seen.insert(line).second) { dirty = true; continue; }    // duplicate

		const std::string root = line.substr(0, a);
		const std::string name = line.substr(a + 1, b - a - 1);
		const std::string result = line.substr(b + 1);

		std::error_code ec;
		if (!fs::is_directory(result, ec)) { dirty = true; continue; } // stale

		keep.push_back(line);
		if (hit.empty() && root == curr_root && name == target) hit = result;
	}
	f.close();

	if (dirty) {
		std::ofstream out(STORE, std::ios::trunc);
		for (const auto &l : keep) out << l << '\n';
	}

	if (!hit.empty()) return hit;
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
	if (target == "..") {std::cout << ".." << std::endl; return 0;}
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
