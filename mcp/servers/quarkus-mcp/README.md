# MCP Greeting Tool

Before to execute the following commands, you must install the Smallrye ACP Client:
```shell
jbang app install --name acp io.smallrye.ai:acp-java-client:0.2.1:runner

// To get the list of the ACP Agents ...
acp registry list -r 
ACP Registry v1.0.0 - 41 agents available
Current platform: darwin-aarch64

ID                        VERSION      DISTRIBUTION   DESCRIPTION
------------------------------------------------------------------------------------------
agoragentic-acp           1.3.0        npx            Agent marketplace with 174+ AI capa...
amp-acp                   0.9.0        binary         ACP wrapper for Amp - the frontier ...
antigravity-acp           1.3.0        binary         Google’s AI coding agent
auggie                    0.36.0       npx            Augment Code's powerful software ag...
autohand                  0.2.1        npx            Autohand Code - AI coding agent pow...
..

// Install an agent
acp registry install claude-acp
```

Next, start ACP with Quarkus MCP server using either stdio, HTTP

## Stdio
```shell
acp run \
  -a claude-acp \
  --backup no \
  -s ./skills/hello/SKILL.md \
  --mcp-server-config '{"type":"stdio","name":"greet-tools","command":"java","args":["-jar", "./mcp/servers/quarkus-mcp/target/quarkus-mcp-1.0.0-SNAPSHOT-runner.jar"]}' \
  -p "Greet"
...
Starting the AI conversation ...
Starting the AI conversation ...
Let me load the greeting MCP tools and call them.
No name was provided, so I'll greet with the defaults.
Here are your greetings:

- **Hello:** Hello from the Quarkus MCP server, Quarkus! - 08/10/2026 11:06:47
- **Bye:** Bye from the Quarkus MCP server, Quarkus! - 08/10/2026 11:06:47

Now saving these to `HELLO.md`.
Greetings saved to `HELLO.md`. Since no name was provided, the default "Quarkus" was used for both the hello and bye greetings.
```
Do some additional tests using `-p Greet <first name>`
```shell
acp run \
        -a claude-acp \
        --backup no \
        -s ./skills/hello/SKILL.md \
        --mcp-server-config '{"type":"stdio","name":"greet-tools","command":"java","args":["-jar", "./mcp/servers/quarkus-mcp/target/quarkus-mcp-1.0.0-SNAPSHOT-runner.jar"]}' \
        -p "Greet Snowdrop"
Starting the AI conversation ...
Calling the greeting tools for Snowdrop.
Here are the greetings for Snowdrop:

- **Hello:** Hello from the Quarkus MCP server, Snowdrop! - 08/10/2026 11:07:25
- **Bye:** Bye from the Quarkus MCP server, Snowdrop! - 08/10/2026 11:07:25
```

## HTTP (server already running)
```shell
acp run \
  -a claude-acp \
  --backup no \
  -s ./skills/hello/SKILL.md \
  --mcp-server-config '{"type":"http","name":"migration-tools","url":"http://localhost:8080/mcp"}' \
  -p "Say Hello to Charles" \
  -o json
```

## HTTP (start server in background first)

Start the Quarkus MCP HTTP server, wait for it to be ready, then run the acp command:
```shell
# Step 1: Start the Quarkus dev server in the background
cd ./mcp/servers/quarkus-mcp
./mvnw quarkus:dev &
QUARKUS_PID=$!
cd -

# Step 2: Wait for the server to be ready
echo "Waiting for Quarkus MCP server to start..."
until curl -s -o /dev/null http://localhost:8080/mcp 2>/dev/null; do
  sleep 2
done
echo "Quarkus MCP server is ready."

# Step 3: Run acp with the HTTP MCP server config
acp run \
  -a claude-acp \
  --backup no \
  -s ./skills/hello/SKILL.md \
  --mcp-server-config '{"type":"http","name":"migration-tools","url":"http://localhost:8080/mcp"}' \
  -p "Say Hello to Charles" \
  -o json

# Step 4: Stop the Quarkus server
kill $QUARKUS_PID 2>/dev/null
```

**Note:** The `--mcp-server-config` flag also accepts a JSON array, so you can register multiple MCP servers in a single `acp run` call, e.g.:
```shell
--mcp-server-config '[{"type":"http","name":"greeting-tools","url":"http://localhost:8080/mcp"},{"type":"stdio","name":"maven-compiler","command":"jbang","args":["run","./MavenMcpServer.java"]}]'
```