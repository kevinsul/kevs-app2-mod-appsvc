# Contributing to Kev's Inventory Management Application

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## ?? How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](../../issues)
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots (if applicable)
   - Environment details (.NET version, OS, etc.)

### Suggesting Enhancements

1. Check [Issues](../../issues) for existing suggestions
2. Create a new issue with:
   - Clear description of the enhancement
   - Use cases and benefits
   - Possible implementation approach

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Write or update tests as needed
5. Ensure all tests pass: `dotnet test`
6. Update documentation if needed
7. Commit with clear messages: `git commit -m 'Add amazing feature'`
8. Push to your fork: `git push origin feature/amazing-feature`
9. Open a Pull Request

## ?? Development Guidelines

### Code Style

- Follow C# coding conventions
- Use meaningful variable and method names
- Add XML comments for public APIs
- Keep methods focused and small
- Use async/await for I/O operations

### Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- First line: brief summary (50 chars or less)
- Detailed explanation in body if needed

Example:
```
Add inventory export functionality

- Implement CSV export for inventory items
- Add export button to inventory list page
- Include unit tests for export service
```

### Testing

- Write unit tests for new features
- Ensure existing tests pass
- Aim for good code coverage
- Test both success and error cases

### Documentation

- Update README.md for new features
- Add inline comments for complex logic
- Update API documentation if applicable
- Include examples in documentation

## ??? Project Structure

```
InventoryApp/
??? Controllers/     # MVC Controllers
??? Models/          # Data models
??? Views/           # Razor views
??? Data/            # EF Core context
??? wwwroot/         # Static files
??? Scripts/         # Database scripts
??? infra/           # Azure infrastructure
```

## ?? Development Workflow

1. **Create Issue**: Describe what you want to work on
2. **Create Branch**: From main branch
3. **Develop**: Make your changes
4. **Test**: Ensure everything works
5. **Document**: Update relevant docs
6. **Commit**: With clear messages
7. **Push**: To your fork
8. **Pull Request**: With description

## ? Pull Request Checklist

Before submitting:

- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings introduced
- [ ] Tests added/updated and passing
- [ ] Works locally
- [ ] Tested in Azure (if applicable)

## ?? What NOT to Include

- Passwords or secrets
- API keys or connection strings
- Personal information
- Large binary files
- IDE-specific files (already in .gitignore)
- Compiled code (bin/, obj/)

## ?? Questions?

- Open a [Discussion](../../discussions)
- Ask in Pull Request comments
- Check existing documentation

## ?? License

By contributing, you agree that your contributions will be licensed under the MIT License.

Thank you for contributing! ??
