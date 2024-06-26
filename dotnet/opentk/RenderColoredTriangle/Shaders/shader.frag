#version 330 core

out vec4 outputColor;
in vec3 vertexColor;

// The Uniform keyword allows you to access a shader variable at any stage of the shader chain
// It's also accessible across all of the main program
// Whatever you set this variable to it keeps it until you either reset the value or updated it
uniform vec4 ourColor;

void main()
{
    outputColor = vec4(vertexColor, 1.0) * ourColor.g;
}
