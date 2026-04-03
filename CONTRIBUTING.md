# Contributing to KubeChamp Platform

Thank you for your interest in contributing to KubeChamp! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Welcome diverse perspectives
- Focus on constructive feedback
- Report issues to maintainers

## How to Contribute

### 1. Reporting Bugs

Before creating a bug report, check existing issues. When reporting:

- Use a clear, descriptive title
- Describe the exact steps to reproduce
- Provide specific examples
- Describe observed behavior and expected behavior
- Include screenshots if applicable
- Mention your environment (OS, K8s version, etc.)

### 2. Suggesting Enhancements

For feature requests:

- Use a clear, descriptive title
- Provide a detailed description of the enhancement
- List some use cases
- Explain why this would be useful
- List similar features in other tools if applicable

### 3. Pull Requests

#### Before Starting

1. Fork the repository
2. Create a branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Test thoroughly
5. Ensure code follows style guidelines

#### Pull Request Process

1. Update README.md with any new features or changes
2. Update documentation as needed
3. Add or update tests
4. Ensure all tests pass: `make test`
5. Ensure code passes linting: `make lint`
6. Submit PR with clear description of changes
7. Link related issues in PR description

#### PR Standards

```
Title: [Type] Brief description

Description:
- What changes are made
- Why these changes are needed
- How to test the changes

Fixes #123
Related to #456
```

## Development Setup

### Clone and Setup

```bash
git clone https://github.com/kubechamp/platform.git
cd platform

# Install dependencies
make install-tools

# Setup pre-commit hooks
pre-commit install
```

### Running Tests

```bash
# Run all tests
make test

# Run specific test
make test TEST=infrastructure

# Run with coverage
make test-coverage
```

### Code Quality

```bash
# Lint code
make lint

# Format code
make fmt

# Security scanning
make security-scan

# Documentation build
make docs-build
```

## Project Structure

```
kubechamp/
├── infrastructure/      # IaC code
├── platform/           # Core platform components
├── ci-cd/              # CI/CD configurations
├── developer-tools/    # CLI and SDKs
├── example-services/   # Reference implementations
├── docs/               # Documentation
├── templates/          # Service templates
└── tests/              # Test suite
```

## Coding Standards

### Go Services

- Follow [Effective Go](https://golang.org/doc/effective_go)
- Use interfaces for abstraction
- Write tests for all packages
- Document exported functions
- Use meaningful variable names

### Terraform Infrastructure

- Use modules for reusability
- Document all variables and outputs
- Use consistent naming conventions
- Include comments for complex logic
- Test with `terraform validate` and `terraform plan`

### Helm Charts

- Use consistent structure
- Document values with comments
- Follow [Helm best practices](https://helm.sh/docs/chart_best_practices/)
- Version charts appropriately
- Include README in each chart

## Documentation

- Keep documentation up-to-date
- Use clear, concise language
- Include code examples where applicable
- Update CHANGELOG.md for significant changes
- Link to related documentation

## Commit Messages

```
[type]: Brief description

Longer explanation of changes if necessary.

Fixes #123
Related to #456
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `infra`

## Release Process

1. Update version numbers (MAJOR.MINOR.PATCH)
2. Update CHANGELOG.md
3. Submit PR for review
4. Merge PR to main branch
5. Create GitHub release with tag
6. Push Helm charts to registry

## Areas for Contribution

### Code

- Bug fixes and improvements
- New features aligned with roadmap
- Additional service templates
- SDK improvements
- Test coverage improvements

### Documentation

- Tutorial writeups
- Best practices guides
- Troubleshooting docs
- API documentation
- Deployment guides for specific platforms

### Operations

- Monitoring and alerting improvements
- Performance optimization
- Security hardening
- Disaster recovery procedures
- Cost optimization strategies

### DevOps

- CI/CD pipeline improvements
- Helm chart enhancements
- Infrastructure as code patterns
- Kubernetes manifests improvements
- Container security scanning

## Support

- **Issues**: [GitHub Issues](https://github.com/kubechamp/platform/issues)
- **Discussions**: [GitHub Discussions](https://github.com/kubechamp/platform/discussions)
- **Slack**: [Community Slack](https://kubechamp.slack.com)
- **Email**: contribute@kubechamp.io

## Recognition

Contributors are recognized in:
- CONTRIBUTORS.md
- GitHub contributors page
- Release notes for significant contributions
- Monthly community highlights

## Legal

By submitting a pull request, you agree that your contribution may be incorporated into KubeChamp under the MIT License.

---

Thank you for helping make KubeChamp better!
