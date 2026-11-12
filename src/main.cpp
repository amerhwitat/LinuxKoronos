#include <cerrno>
#include <cstring>
#include <iostream>
#include <string>
#include <vector>
#include <sys/utsname.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
namespace {
int info() {
  utsname u{};
  if (uname(&u) != 0) { std::cerr << "uname: " << std::strerror(errno) << '\\n'; return 1; }
  std::cout << "LinuxKoronos hosted runtime 0.1.0\\n"
            << "kernel=" << u.sysname << " " << u.release << "\\n"
            << "machine=" << u.machine << "\\n"
            << "execution=unprivileged-linux-process\\n";
  return 0;
}
int profile() {
  std::cout << "profile=linux-hosted-v1\\nprocess=linux\\nfilesystem=host-managed\\n"
            << "network=host-managed\\ndevice_access=not-granted-by-default\\n"
            << "bare_metal_kernel=false\\n";
  return 0;
}
int run_command(int argc, char** argv) {
  if (argc < 4 || std::string(argv[2]) != "--") {
    std::cerr << "usage: koronos-host run -- PROGRAM [ARG ...]\\n"; return 2;
  }
  std::vector<char*> child_argv;
  for (int i = 3; i < argc; ++i) child_argv.push_back(argv[i]);
  child_argv.push_back(nullptr);
  const pid_t pid = fork();
  if (pid < 0) { std::cerr << "fork: " << std::strerror(errno) << '\\n'; return 1; }
  if (pid == 0) {
    execvp(child_argv[0], child_argv.data());
    std::cerr << "exec " << child_argv[0] << ": " << std::strerror(errno) << '\\n';
    _exit(errno == ENOENT ? 127 : 126);
  }
  int status = 0;
  while (waitpid(pid, &status, 0) < 0) {
    if (errno == EINTR) continue;
    std::cerr << "waitpid: " << std::strerror(errno) << '\\n'; return 1;
  }
  if (WIFEXITED(status)) return WEXITSTATUS(status);
  if (WIFSIGNALED(status)) return 128 + WTERMSIG(status);
  return 1;
}
}
int main(int argc, char** argv) {
  if (argc < 2 || std::string(argv[1]) == "--help" || std::string(argv[1]) == "-h") {
    std::cout << "usage: koronos-host {info|profile|run -- PROGRAM [ARG ...]}\\n";
    return argc < 2 ? 2 : 0;
  }
  const std::string cmd(argv[1]);
  if (cmd == "info") return info();
  if (cmd == "profile") return profile();
  if (cmd == "run") return run_command(argc, argv);
  std::cerr << "unknown command: " << cmd << '\\n'; return 2;
}
