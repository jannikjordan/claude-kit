#!/usr/bin/env bash
# ==============================================================================
# Claude Session Templates - Start sessions with pre-configured prompts
# ==============================================================================

template="${1:-}"

# Template directory
TEMPLATE_DIR="$HOME/.claude/templates"
mkdir -p "$TEMPLATE_DIR"

# Define templates
case "$template" in
    refactor)
        prompt="I need help refactoring code. Please:
1. Analyze the current code structure
2. Identify areas for improvement
3. Suggest refactoring strategies
4. Implement changes incrementally
5. Ensure tests pass after each change

Let's start by exploring the codebase."
        ;;

    feature)
        prompt="I want to implement a new feature. Please:
1. Understand the requirements
2. Design the architecture
3. Identify files that need changes
4. Implement the feature incrementally
5. Add tests for the new functionality
6. Update documentation

What feature would you like to add?"
        ;;

    bugfix)
        prompt="I need to debug an issue. Please help me:
1. Reproduce the bug
2. Identify the root cause
3. Propose a fix
4. Implement the solution
5. Add tests to prevent regression

Describe the bug you're experiencing."
        ;;

    review)
        prompt="Please review this code for:
- Code quality and best practices
- Potential bugs or edge cases
- Performance issues
- Security vulnerabilities
- Testing coverage

Let's start with a high-level overview of the codebase."
        ;;

    test)
        prompt="I need help writing tests. Please:
1. Analyze the code to be tested
2. Identify test cases (happy path, edge cases, errors)
3. Write comprehensive test coverage
4. Ensure tests are maintainable

Which files or functions need tests?"
        ;;

    docs)
        prompt="Help me improve documentation:
1. Review existing documentation
2. Identify gaps or unclear sections
3. Add/improve code comments
4. Update README and guides
5. Add examples where helpful

Let's start by reviewing what documentation exists."
        ;;

    security)
        prompt="Security audit - please check for:
- SQL injection vulnerabilities
- XSS vulnerabilities
- CSRF protection
- Authentication/authorization issues
- Input validation
- Secrets in code
- Dependency vulnerabilities

Let's audit the codebase systematically."
        ;;

    *)
        echo "Usage: claude-new [template]"
        echo ""
        echo "Available templates:"
        echo "  refactor  - Code refactoring"
        echo "  feature   - New feature implementation"
        echo "  bugfix    - Bug investigation and fix"
        echo "  review    - Code review"
        echo "  test      - Write tests"
        echo "  docs      - Improve documentation"
        echo "  security  - Security audit"
        echo ""
        echo "Example: claude-new refactor"
        exit 1
        ;;
esac

# Start Claude with template prompt
exec claude -m "$prompt"
