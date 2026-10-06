# MCP Greeting Tool

1. Stdio
```shell
acp run \
  -a claude-acp \
  --backup no \
  -s ./mcp-tool-benchmark/mcp-servers/quarkus-mcp/SKILL.md \
  --mcp-server-config '{"type":"stdio","name":"migration-tools","command":"java","args":["-jar", "./mcp-tool-benchmark/mcp-servers/quarkus-mcp-stdio/target/mcp-stdio-quickstart-1.0.0-SNAPSHOT-runner.jar"]}' \
  -p "Say Hello to Charles" \
  -o json
```
This is horribly slow to get a response. Why: I don't know ? Perhaps due to the fact that both use same: stdio !

2. HTTP
```shell
acp run \
  -a claude-acp \
  --backup no \
  -s ./mcp-tool-benchmark/mcp-servers/quarkus-mcp/SKILL.md \
  --mcp-server-config '{"type":"http","name":"migration-tools","url":"http://localhost:8080/mcp"}' \
  -p "Say Hello to Charles" \
  -o json
```