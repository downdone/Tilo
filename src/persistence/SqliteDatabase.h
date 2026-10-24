#pragma once
#include "domain/Task.h"
#include <QSqlDatabase>

namespace tilo {

class MigrationManager {
public:
    static Result<void> initialize(QSqlDatabase& db);
};

class SqliteDatabase final {
public:
    SqliteDatabase();
    ~SqliteDatabase();
    Result<void> open(const QString& path);
    // Closes the connection so the underlying file can be moved aside during
    // recovery from an unusable database.
    void close();
    Result<QString> createSnapshot(const QString& directory);
    Result<void> ensureDailySnapshot();
    Result<void> checkIntegrity() const;
    QSqlDatabase connection() const { return m_db; } // Persistence layer/tests only.
private:
    QString m_connectionName;
    QSqlDatabase m_db;
};

} // namespace tilo
