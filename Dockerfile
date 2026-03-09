FROM melkortf/tf2-sourcemod:latest

RUN wget "https://github.com/dordnung/System2/releases/download/v3.3.2/system2.zip" -O system2.zip \
  && echo "0a6f47243e280a9afee390b0943f9cf7f27f4f6c5a813a5ef63fb30162fccf5b  system2.zip" | sha256sum -c \
  && unzip -o system2.zip -d "${SERVER_DIR}/tf/addons/sourcemod/" \
  && rm -f system2.zip

COPY connector.smx "$SERVER_DIR/tf/addons/sourcemod/plugins/connector.smx"
