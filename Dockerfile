FROM ubuntu:20.04 AS base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG SECRET_KEY
ENV SECRET_KEY=${SECRET_KEY}

WORKDIR /app

# Copy my scripts from the local MacBook I have entitled "Montana's MacBook" 
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*

RUN /usr/local/bin/custom-build-script.sh
FROM base AS builder

COPY src/ /app/src/
COPY setup.py /app/
COPY requirements.txt /app/

RUN apt-get update && apt-get install -y python3-pip && \
    pip3 install --no-cache-dir -r requirements.txt

RUN python3 setup.py build

FROM ubuntu:20.04 AS runtime

COPY --from=builder /app /app

RUN apt-get update && apt-get install -y python3-minimal && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV APP_ENV=production

HEALTHCHECK CMD ["/usr/local/bin/health-check-script.sh"]

STOPSIGNAL SIGTERM

RUN groupadd -r appgroup && useradd --no-log-init -r -g appgroup appuser
USER appuser

EXPOSE 8080

CMD ["python3", "-m", "app"]
