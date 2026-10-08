package org.acme;

import io.quarkiverse.mcp.server.Resource;
import io.quarkiverse.mcp.server.TextResourceContents;
import java.nio.charset.StandardCharsets;

public class FileResources {

    @Resource(uri = "file:///config.json")
    TextResourceContents configFile() throws Exception {
        try (var is = getClass().getClassLoader()
                .getResourceAsStream("config.json")) {
            if (is == null) {
                return TextResourceContents.create(
                        "file:///config.json",
                        "{\"error\": \"config.json not found on classpath\"}");
            }
            String content = new String(is.readAllBytes(), StandardCharsets.UTF_8);
            return TextResourceContents.create(
                    "file:///config.json",
                    content);
        }
    }
}