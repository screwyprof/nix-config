# alias-teacher

An enhanced ZSH plugin that helps you learn and use shell aliases effectively. This is a fork of [zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use) with significant improvements for better alias discovery and learning.

## The Story

This project began when I encountered a frustrating issue with the original YSU plugin. Despite having numerous git aliases configured, when I typed `git status`, the plugin would only suggest the generic `G` alias (for `git`) instead of the more specific `GwS` alias (for `git status`). This defeated the purpose of having specific aliases and made it harder to learn about them.

### The Problem

```bash
# Original behavior
$ git status
Found existing alias for "git". You should use: "G"
# Never showed that GwS exists!
```

With YSU's hardcore mode enabled, the shell would be killed before showing better alternatives, making it impossible to discover more specific aliases.

### The Journey

1. **Initial Investigation**: We discovered that YSU matched aliases in order and stopped at the first match
2. **Algorithm Study**: We examined how [alias-tips](https://github.com/djui/alias-tips) handled this better
3. **Implementation**: We rewrote the matching algorithm to find the most specific match
4. **Enhancement**: We added alias discovery to help users learn about related aliases
5. **Result**: A more intelligent plugin that actually helps you learn your aliases

## Key Improvements

### 1. Smarter Matching Algorithm

The plugin now finds the **most specific** alias that matches your command:

```bash
# New behavior
$ git status
Found existing alias for "git status". You should use: "GwS"
```

### 2. Alias Discovery

When only a generic alias matches, the plugin shows related aliases you might want to use:

```bash
$ git diff
Found existing alias for "git". You should use: "G"
Related aliases for "git diff":
  Gwd: git diff --no-ext-diff
  Gid: git diff --no-ext-diff --cached
  GwD: git diff --no-ext-diff --word-diff
  GiD: git diff --no-ext-diff --cached --word-diff
```

This transforms the plugin from just a reminder into a learning tool that helps you discover aliases you didn't know existed.

### 3. Better Hardcore Mode

With `YSU_HARDCORE=1` and `YSU_MODE=ALL`, the plugin now shows only the best match before blocking, preventing the frustrating situation where you're blocked before seeing the most useful suggestion.

## Installation

### With Nix (Recommended)

This plugin is designed to work with Nix and integrates with zim. Add it to your flake configuration:

```nix
{
  alias-teacher = final.callPackage ./pkgs/alias-teacher { };
}
```

Then in your zsh configuration:

```nix
"${pkgs.alias-teacher}/share/zsh/plugins/alias-teacher --source alias-teacher.plugin.zsh"
```

### Manual Installation

1. Clone this repository
2. Source `alias-teacher.plugin.zsh` in your `.zshrc`

## Configuration

The plugin maintains full compatibility with YSU environment variables:

```bash
# Show all matching aliases or just the best match
export YSU_MODE="ALL"  # or "BESTMATCH" (default)

# Block command execution if an alias exists
export YSU_HARDCORE="1"

# Show messages before or after command execution
export YSU_MESSAGE_POSITION="after"  # or "before" (default)

# Customize the message format
export YSU_MESSAGE_FORMAT="💡 Alias tip: %command → %alias"

# Ignore specific aliases
export YSU_IGNORED_ALIASES=("g" "ll")
```

## Technical Details

### Matching Algorithm

1. **Build sorted list**: Aliases are sorted by their expanded form length (longest first)
2. **Find matches**: Check which aliases match the typed command
3. **Select best**: The longest matching expansion wins
4. **Show discovery**: If only generic matches found, show related specific aliases

### Code Example

The core improvement is in how we process matches:

```zsh
# Old: First match wins
if [[ "$typed" = "$value" || "$typed" = "$value "* ]]; then
    # Show this match and stop
fi

# New: Find ALL matches, then pick the best
# Sort by expansion length, show most specific first
```

## Future Plans

- [ ] Performance optimizations for large alias sets
- [ ] Configurable discovery patterns
- [ ] Integration with shell history to learn usage patterns
- [ ] Possible Rust implementation for blazing fast performance

## Why "alias-teacher"?

The original YSU was about reminding you to use aliases you already knew about. This fork is about **teaching** you aliases you didn't know existed. It's not just a reminder—it's a learning tool.

## Credits

This project is based on [zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use) by Michael Aquilina. We're grateful for the solid foundation that made these enhancements possible.

## License

GPL-3.0 (same as the original project)

---

*"The best way to learn your aliases is to have them suggested at the right time."*