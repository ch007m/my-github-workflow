package com.example;

public class HelloWorld {

    public String greet(String name) {
        return "Hello, " + name + "!";
    }

    public static void main(String[] args) {
        HelloWorld app = new HelloWorld();
        System.out.println(app.greet("World"));
    }
}
