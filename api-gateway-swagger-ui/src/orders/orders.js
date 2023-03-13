module.exports.handler = async (event, context) => {
    let response = {
        statusCode: 200,
        body: JSON.stringify('Hello from Lambda! Orders Response')
    };
    return response;
};