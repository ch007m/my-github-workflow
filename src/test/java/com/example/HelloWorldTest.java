package com.example;

import org.junit.Test;
import static org.junit.Assert.assertEquals;

public class HelloWorldTest {

    @Test
    public void testGreet() {
        HelloWorld app = new HelloWorld();
        assertEquals("Hello, World!", app.greet("World"));
    }

    @Test
    public void testGreetWithName() {
        HelloWorld app = new HelloWorld();
        assertEquals("Hello, Alice!", app.greet("Alice"));
    }
}
