# Filesystem Analysis

Analyze the `/tmp` directory by running `npx -y @anthropic-ai/mcp-filesystem /tmp` with your Bash tool to access the filesystem.

1. List all files and directories in `/tmp`
2. Count the total number of entries
3. Identify any project directories (containing pom.xml, package.json, or build.gradle)
4. For each project found, read its build file and extract the project name and version

Report your findings in this format:
- **Total items in /tmp**: (count)
- **Project directories found**: (list with name and version)
- **Summary**: (2-3 sentence overview)

Do not modify any files.
