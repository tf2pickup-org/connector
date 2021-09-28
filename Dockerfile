FROM melkortf/tf2-sourcemod:latest

RUN wget "https://forums.alliedmods.net/attachment.php?attachmentid=188744&d=1618607414" -O system2.zip \
  && unzip -o system2.zip -d "${SERVER_DIR}/tf/addons/sourcemod/" \
  && rm -f system2.zip \
  && wget "https://github.com/KyleSanderson/SteamWorks/releases/download/1.2.3c/package-lin.tgz" -O steamworks.tgz \
  && tar -xf steamworks.tgz --strip-components=1 -C "${SERVER_DIR}/tf/" \
  && rm -f steamworks.tgz

COPY scripting/connector.smx "$SERVER_DIR/tf/addons/sourcemod/plugins/connector.smx"
