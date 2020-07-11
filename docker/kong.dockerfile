FROM kong
LABEL description="Kong with kong-oidc plugin"

USER root

RUN luarocks install kong-oidc

USER kong
