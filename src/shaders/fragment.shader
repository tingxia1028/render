#version 330 core

out vec4 FragColor;
in vec3 Normal;
in vec3 FragPos;
in vec2 TexCoords;

struct DirectLight{
    vec3 direction;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

struct PointLight{
    vec3 position;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float constant;
    float linear;
    float quadratic;
};

struct SpotLight{
    vec3 position;
    vec3 direction;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float constant;
    float linear;
    float quadratic;
    float cutoff;
    float outCutoff;
};

struct Material{
    vec3 diffuseColor;
    vec3 specularColor;
    float shininess;
    bool hasDiffuseTex;
    bool hasSpecularTex;
    sampler2D diffuse;
    sampler2D specular;
};

#define DIRCECT_LIGHTS 5
#define POINT_LIGHTS 5
#define SPOT_LIGHTS 5
#define MATERIALS 1
uniform int dirNum;
uniform int pointNum;
uniform int spotNum;
uniform DirectLight directLights[DIRCECT_LIGHTS];
uniform PointLight pointLights[POINT_LIGHTS];
uniform SpotLight spotLights[SPOT_LIGHTS];
// only one material present, may extend to mix/blend later
uniform Material materials[MATERIALS];
uniform vec3 viewPos;

vec3 CaculateDirectLight(DirectLight light, vec3 normal, vec3 viewDir, vec3 diffuseSampler, vec3 specularSampler);
vec3 CaculatePointLight(PointLight light, vec3 normal, vec3 viewDir, vec3 diffuseSampler, vec3 specularSampler);
vec3 CaculateSpotLight(SpotLight light, vec3 normal, vec3 viewDir, vec3 diffuseSampler, vec3 specularSampler);

void main()
{
    vec3 resultColor = vec3(0.0f);
    vec3 norm = normalize(Normal);
    vec3 viewDir = normalize(viewPos - FragPos);
    vec3 diffuseSampler;
    if(materials[0].hasDiffuseTex){
        diffuseSampler = vec3(texture(materials[0].diffuse, TexCoords));
    }else{
        diffuseSampler = materials[0].diffuseColor;
    }
    vec3 specularSampler;
    if(materials[0].hasSpecularTex){
        specularSampler = vec3(texture(materials[0].specular, TexCoords));
    }else{
        specularSampler = materials[0].specularColor;
    }

    for(int i = 0; i< dirNum; ++i){
        resultColor += CaculateDirectLight(directLights[i], norm, viewDir, diffuseSampler, specularSampler);
    }
    for(int i = 0; i< pointNum; ++i){
        resultColor += CaculatePointLight(pointLights[i], norm, viewDir, diffuseSampler, specularSampler);
    }
    for(int i = 0; i< spotNum; ++i){
        resultColor += CaculateSpotLight(spotLights[i], norm, viewDir, diffuseSampler, specularSampler);
    }
    FragColor = vec4(resultColor, 1.0f);
}

vec3 CaculateDirectLight(DirectLight light, vec3 normal, vec3 viewDir, vec3 diffuseSampler, vec3 specularSampler){
    vec3 lightDir = normalize(-light.direction);
    // diffuse shading
    float diff = max(dot(normal, lightDir), 0.0);
    // specular shading
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), materials[0].shininess);
    // combine results
    vec3 ambient = light.ambient * diffuseSampler;
    vec3 diffuse = light.diffuse * diff * diffuseSampler;
    vec3 specular = light.specular * spec * specularSampler;
    return (ambient + diffuse + specular);
}

vec3 CaculatePointLight(PointLight light, vec3 normal, vec3 viewDir, vec3 diffuseSampler, vec3 specularSampler){
    vec3 lightDir = normalize(light.position - FragPos);
    // diffuse shading
    float diff = max(dot(normal, lightDir), 0.0);
    // specular shading
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), materials[0].shininess);
    // combine results
    vec3 ambient = light.ambient * diffuseSampler;
    vec3 diffuse = light.diffuse * diff * diffuseSampler;
    vec3 specular = light.specular * spec * specularSampler;
    // attenuation
    float distance    = length(light.position - FragPos);
    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));
    ambient *= attenuation;
    diffuse *= attenuation;
    specular *= attenuation;
    return (ambient + diffuse + specular);
}

vec3 CaculateSpotLight(SpotLight light, vec3 normal, vec3 viewDir, vec3 diffuseSampler, vec3 specularSampler){
    vec3 lightDir = normalize(light.position - FragPos);
    // diffuse shading
    float diff = max(dot(normal, lightDir), 0.0);
    // specular shading
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), materials[0].shininess);
    // combine results
    vec3 ambient = light.ambient * diffuseSampler;
    vec3 diffuse = light.diffuse * diff * diffuseSampler;
    vec3 specular = light.specular * spec * specularSampler;
    // attenuation
    float distance    = length(light.position - FragPos);
    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));
    // spotlight intensity
    float theta = dot(lightDir, normalize(-light.direction));
    float epsilon = light.cutoff - light.outCutoff;
    float intensity = clamp((theta - light.outCutoff) / epsilon, 0.0, 1.0);
    ambient *= attenuation * intensity;
    diffuse *= attenuation * intensity;
    specular *= attenuation * intensity;
    return (ambient + diffuse + specular);
}