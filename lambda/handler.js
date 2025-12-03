const { RDSDataClient, ExecuteStatementCommand } = require("@aws-sdk/client-rds-data");

const client = new RDSDataClient({});

const dbConfig = {
  secretArn: process.env.DB_SECRET_ARN,
  resourceArn: process.env.DB_CLUSTER_ARN,
  database: process.env.DB_NAME || "drpoc",
};

exports.handler = async (event) => {
  try {
    const path  = event.requestContext?.http?.path || "/";
    const method = event.requestContext?.http?.method || "GET";

    if (path === "/users" && method === "GET") {
      const cmd = new ExecuteStatementCommand({
        ...dbConfig,
        sql: "SELECT id, name, created_at FROM users ORDER BY id",
      });
      const res = await client.send(cmd);

      const rows = (res.records || []).map(r => ({
        id: Number(r[0].longValue),
        name: r[1].stringValue,
        created_at: r[2].stringValue
      }));

      return json(200, rows);
    }

    if (path === "/users" && method === "POST") {
      const body = JSON.parse(event.body || "{}");
      if (!body.name) return json(400, { message: "name is required" });

      const cmd = new ExecuteStatementCommand({
        ...dbConfig,
        sql: "INSERT INTO users (name) VALUES (:name)",
        parameters: [{ name: "name", value: { stringValue: body.name } }],
      });
      await client.send(cmd);
      return json(201, { message: "created" });
    }

    if (path === "/health" && method === "GET") {
      return json(200, { status: "ok" });
    }

    return json(404, { message: "not found" });
  } catch (err) {
    console.error(err);
    return json(500, { message: "internal error" });
  }
};

function json(statusCode, body) {
  return {
    statusCode,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  };
}
