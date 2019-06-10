const fs = require("fs");

function saveFile(content, filePath) {
    const serializedContent = JSON.stringify(content, null, 2);
    fs.writeFileSync(filePath, serializedContent);
}

function loadFile(filePath) {
    const content = fs.readFileSync(filePath);
    const parsedContent = JSON.parse(content);
    return parsedContent;
}

const filePath = process.argv[2];
const parsedContent = loadFile(filePath);

parameterizeRGInParameters();
parameterizeSubInConnections();

saveFile(parsedContent, filePath);

function parameterizeSubInConnections() {
    for (let resource of parsedContent.resources) {
        if (resource.properties.parameters && resource.properties.parameters["$connections"]) {
            const connections = resource.properties.parameters["$connections"].value;
            for (let connectionName in connections) {
                const connection = connections[connectionName];
                parameterizeSubInConnectionId(connection);
            }
        }
    }
}

function parameterizeRGInParameters() {
    for (let parameterName in parsedContent.parameters) {
        const parameter = parsedContent.parameters[parameterName];
        parameterizeRGinDefaultValue(parameter);
    }
}

function parameterizeSubInConnectionId(connection) {
    const regex = /\/subscriptions\/[a-fA-F0-9-]+(\/providers\/Microsoft.Web\/locations\/)[a-z0-9-]+(\/managedApis\/[a-z0-9A-Z-]+)/;
    const regexMatch = regex.exec(connection.id);
    if (!!regexMatch) {
        const providerAPI = regexMatch[1];
        const provider = regexMatch[2];
        const newConnectionId = `[concat(subscription().id, '${providerAPI}', resourceGroup().location, '${provider}')]`;
        connection.id = newConnectionId;
    }
}

function parameterizeRGinDefaultValue(parameterValue) {
    const regex = /^\/subscriptions\/[a-fA-F0-9-]+\/resourceGroups\/[^\/]+(\/.+$)/;
    const regexMatch = regex.exec(parameterValue.defaultValue);
    if (!!regexMatch) {
        const endOfLine = regexMatch[1];
        const newDefaultValue = `[concat(resourceGroup().id, '${endOfLine}')]`;
        parameterValue.defaultValue = newDefaultValue;
    }
}
