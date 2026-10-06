---
name: maven-compile-test
description: Compile a Java project using the maven_compile MCP tool
---

# Instructions

- Use the `maven_compile` tool to compile the project at root of the git repository: `pom.xml`
- If compilation succeeds, report "BUILD SUCCESS"
- If compilation fails, extract the first error from the output and report it

The agent discovers the maven_compile tool automatically because it's exposed by the MCP server.