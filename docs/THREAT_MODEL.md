# Threat model

The interposer is loaded through `LD_PRELOAD` into Steam's CEF helper. It intercepts CEF initialization and calls Steam's exported scaling function. The process name, environment variable, and resolved symbols form the trust boundary. An `LD_PRELOAD` library runs with the target process's privileges, so a scope error could affect unrelated applications.

The library must remain inert outside the exact `steamwebhelper` process, reject malformed and non-finite scale values, avoid recursive hooks, and fail open when CEF symbols are absent or initialization fails. Steam updates may change ABI or symbols. The intended caller is the desktop user; the package does not require elevated privileges.

Security review should inspect process matching, complete numeric parsing, symbol resolution, linker hardening, and behavior with a changed Steam CEF ABI. Mock tests and sanitizer builds cover the expected paths; a real Steam version needs manual compatibility testing before a release.
