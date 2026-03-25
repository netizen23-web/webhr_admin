import mysql from "mysql2/promise";

declare global {
  var __mysqlPool: mysql.Pool | undefined;
  var __mysqlPoolKey: string | undefined;
}

function requireEnv(name: string, fallback?: string) {
  const value = process.env[name] ?? fallback;

  if (!value) {
    throw new Error(`Missing environment variable: ${name}`);
  }

  return value;
}

function buildDbConfig() {
  const mysqlUrl = process.env.MYSQL_URL || process.env.DATABASE_URL;
  if (mysqlUrl) {
    const url = new URL(mysqlUrl);
    return {
      host: url.hostname,
      port: Number(url.port) || 3306,
      user: decodeURIComponent(url.username),
      password: decodeURIComponent(url.password),
      database: url.pathname.replace(/^\//, ""),
    };
  }

  return {
    host: requireEnv("DB_HOST", process.env.MYSQLHOST ?? "127.0.0.1"),
    port: Number(requireEnv("DB_PORT", process.env.MYSQLPORT ?? "3306")),
    user: requireEnv("DB_USER", process.env.MYSQLUSER ?? "root"),
    password: process.env.DB_PASSWORD ?? process.env.MYSQLPASSWORD ?? "",
    database: requireEnv("DB_NAME", process.env.MYSQLDATABASE ?? "hris_admin_only"),
  };
}

export const dbConfig = buildDbConfig();

const poolKey = `${dbConfig.host}:${dbConfig.port}/${dbConfig.database}:${dbConfig.user}`;

export const pool =
  global.__mysqlPool && global.__mysqlPoolKey === poolKey
    ? global.__mysqlPool
    : mysql.createPool({
        ...dbConfig,
        connectionLimit: 10,
        waitForConnections: true,
        namedPlaceholders: true,
      });

if (process.env.NODE_ENV !== "production") {
  global.__mysqlPool = pool;
  global.__mysqlPoolKey = poolKey;
}
