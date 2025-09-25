# Contributing to Auth SDK Generator

Thank you for your interest in contributing to the Auth SDK Generator project! We welcome contributions from the community.

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- A clear and descriptive title
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- System information (OS, OCaml version, etc.)
- Relevant `.auth` specification files (if applicable)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- A clear and descriptive title
- Detailed description of the proposed functionality
- Use cases and examples
- Why this enhancement would be useful

### Pull Requests

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Make your changes
4. Add tests for your changes
5. Ensure all tests pass (`make test`)
6. Format your code properly
7. Commit your changes with a descriptive commit message
8. Push to the branch (`git push origin feature/AmazingFeature`)
9. Open a Pull Request

## Development Process

### Setting Up Development Environment

```bash
# Clone your fork
git clone https://github.com/your-username/auth-sdk-generator.git
cd auth-sdk-generator

# Install dependencies
opam install . --deps-only

# Build the project
make build

# Run tests
make test
```

### Code Style

- Follow OCaml community conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused
- Ensure code compiles without warnings

### Testing

- Add unit tests for new functionality
- Update existing tests when modifying behavior
- Ensure all tests pass before submitting PR
- Test generated SDKs in their target languages

### Commit Messages

- Use clear and meaningful commit messages
- Start with a verb in present tense ("Add", "Fix", "Update")
- Keep the first line under 50 characters
- Add detailed description if needed

Example:
```
Add Ruby SDK generator support

- Implement Ruby code generation module
- Add Ruby-specific validation
- Include RSpec test generation
- Update documentation
```

## Adding New Language Support

To add a new language generator:

1. Create a new module in `lib/generators/<language>/`
2. Implement the generator interface
3. Add validation in `lib/validators/<language>_validator.ml`
4. Add tests in `test/`
5. Update documentation
6. Add example specifications

## Code of Conduct

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Expected Behavior

- Be respectful and inclusive
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

### Unacceptable Behavior

- Harassment of any kind
- Discriminatory language or actions
- Personal attacks
- Publishing others' private information
- Other conduct which could reasonably be considered inappropriate

## Questions?

Feel free to open an issue with the "question" label or start a discussion in the GitHub Discussions area.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.