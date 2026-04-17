FROM postgres:15-alpine

LABEL maintainer="Hackathon Team"
LABEL description="PostgreSQL for Hackathon Evaluation System"

# Install additional tools for monitoring
RUN apk add --no-cache \
    postgresql-contrib \
    pgbackrest \
    curl \
    jq \
    && rm -rf /var/cache/apk/*

# Copy custom configuration
COPY conf/postgresql.conf /etc/postgresql/postgresql.conf
COPY conf/pg_hba.conf /etc/postgresql/pg_hba.conf

# Set custom config
RUN chmod 644 /etc/postgresql/postgresql.conf && \
    chmod 600 /etc/postgresql/pg_hba.conf

# Health check script
COPY scripts/healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

# Expose PostgreSQL port
EXPOSE 5432

# Use custom config
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]