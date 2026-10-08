## How to play with MCP


To call a jbang mcp server able to compile a maven project, execute the following command:
```shell
acp run \
  -a claude-acp \
  --backup no \
  -s ./mcp-tool-benchmark/skills/maven-compile-test/SKILL.md \
  --mcp-server-config '{"type":"stdio","name":"maven-compiler","command":"jbang","args":["run", "./mcp-tool-benchmark/mcp-servers/jbang-maven/MavenMcpServer.java"]}' \
  -p "Compile the project" \
  -o json
```

This command will use jbang and mcp java [sdk](https://github.com/modelcontextprotocol/java-sdk) to run a MCP Server exposing as function/tool: `maven_compile`

```java
///usr/bin/env jbang "$0" "$@" ; exit $?
//DEPS io.modelcontextprotocol.sdk:mcp:2.0.1
//DEPS org.slf4j:slf4j-nop:2.0.13

import io.modelcontextprotocol.server.McpServer;
import io.modelcontextprotocol.server.McpSyncServer;
import io.modelcontextprotocol.server.McpServerFeatures.SyncToolSpecification;
import io.modelcontextprotocol.server.transport.StdioServerTransportProvider;
import io.modelcontextprotocol.spec.McpSchema;
import io.modelcontextprotocol.spec.McpSchema.CallToolResult;
import io.modelcontextprotocol.spec.McpSchema.TextContent;
import io.modelcontextprotocol.spec.McpSchema.Tool;
import io.modelcontextprotocol.json.McpJsonDefaults;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.util.List;
import java.util.Map;

public class MavenMcpServer {

    public static void main(String[] args) throws InterruptedException {
        StdioServerTransportProvider transportProvider =
                new StdioServerTransportProvider(McpJsonDefaults.getMapper());

        var inputSchema = Map.of(
                "type", "object",
                "properties", Map.of(
                        "pom_path", Map.of(
                                "type", "string",
                                "description", "Path to pom.xml"
                        )
                ),
                "required", List.of()
        );

        McpSyncServer server = McpServer.sync(transportProvider)
                .serverInfo("jbang-maven-mcp", "1.0.0")
                .toolCall(
                        Tool.builder("maven_compile", inputSchema)
                                .description("Compiles the Java project using Maven")
                                .build(),
                        (exchange, request) -> {
                            String pomPath = (String) request.arguments().getOrDefault("pom_path", "./pom.xml");
                            try {
                                String cwd = System.getProperty("user.dir");
                                File pomFile = new File(pomPath).getAbsoluteFile();
                                File projectDir = pomFile.getParentFile();

                                ProcessBuilder pb = new ProcessBuilder("mvn", "compile", "-DskipTests", "-f", pomFile.getPath());
                                pb.directory(projectDir);
                                pb.redirectErrorStream(true);
                                Process p = pb.start();

                                BufferedReader reader = new BufferedReader(new InputStreamReader(p.getInputStream()));
                                StringBuilder output = new StringBuilder();
                                String line;
                                while ((line = reader.readLine()) != null) {
                                    output.append(line).append("\n");
                                }
                                int exitCode = p.waitFor();

                                boolean targetExists = new File(projectDir, "target").exists();

                                output.append("\n--- Diagnostics ---\n");
                                output.append("MCP server CWD: ").append(cwd).append("\n");
                                output.append("Resolved pom: ").append(pomFile.getPath()).append("\n");
                                output.append("Maven ran in: ").append(projectDir.getPath()).append("\n");
                                output.append("target/ exists: ").append(targetExists).append("\n");

                                return CallToolResult.builder()
                                        .addTextContent(output.toString())
                                        .isError(exitCode != 0)
                                        .build();
                            } catch (Exception e) {
                                return CallToolResult.builder()
                                        .addTextContent("Execution error: " + e.getMessage())
                                        .isError(true)
                                        .build();
                            }
                        })
                .build();

        Thread.currentThread().join();
    }
}
```
To execute the command, the SKILL must include a statement telling to perform: "Use the `maven_compile` tool ..."

When you will execute the ACP command, then you must see as messages:
```shell
Starting the AI conversation ...
Let me read the skill file first.
Now let me load the `maven_compile` MCP tool schema.
Running Maven compilation on the project.
**BUILD SUCCESS** — the `helloworld` project compiled successfully (1 source file, Java 21, 0.465s).
```