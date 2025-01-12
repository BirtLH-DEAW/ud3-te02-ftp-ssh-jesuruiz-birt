# Primera etapa: Construcción intermedia
FROM ubuntu:latest AS intermediate

# Damos información sobre la imagen que estamos creando
LABEL \
    version="1.0" \
    description="Ubuntu + Apache2 + proftpd + FTP seguro" \
    maintainer="jesuruiz <jesuruiz@birt.eus>"

# Actualizamos la lista de paquetes e instalamos las dependencias necesarias
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y nano apache2 proftpd proftpd-mod-crypto openssl ssh git && \
    rm -rf /var/lib/apt/lists/*

# Copiamos la clave privada al contenedor temporalmente
COPY ssh/id_rsa /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa

# Aceptar el dominio github.com
RUN touch /root/.ssh/known_hosts && \
    ssh-keyscan -H github.com >> /root/.ssh/known_hosts

# Clonar el repositorio privado de GitHub
RUN GIT_SSH_COMMAND='ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no' git clone git@github.com:deaw-birt/UD3-ftp_anonimo.git /srv/ftp/proyecto

# Segunda etapa: Imagen final
FROM ubuntu:latest

# Damos información sobre la imagen que estamos creando
LABEL \
    version="1.0" \
    description="Ubuntu + Apache2 + proftpd + FTP seguro" \
    maintainer="jesuruiz <jesuruiz@birt.eus>"

# Actualizamos la lista de paquetes e instalamos las dependencias necesarias
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y nano apache2 proftpd proftpd-mod-crypto openssl ssh && \
    rm -rf /var/lib/apt/lists/*

# Creamos el grupo ftp 
RUN groupadd ftp

# Creamos el usuario jesuruiz1
RUN useradd -m -d /var/www/html/sitio1 -s /usr/sbin/nologin jesuruiz1 && \
    echo 'jesuruiz1:deaw' | chpasswd && \ 
    chown -R jesuruiz1:www-data /var/www/html/sitio1 && \ 
    chmod -R 755 /var/www/html/sitio1 

# Creamos el usuario 'jesuruiz2'
RUN useradd -m -d /var/www/html/sitio2 -s /bin/bash jesuruiz2 && \
    echo 'jesuruiz2:deaw' | chpasswd && \ 
    chown -R jesuruiz2:www-data /var/www/html/sitio2 && \ 
    chmod -R 755 /var/www/html/sitio2

# Creamos el usuario 'jesuruiz' 
RUN useradd -m -d /srv/ftp -s /usr/sbin/nologin jesuruiz && \ 
    echo 'jesuruiz:deaw' | chpasswd && \ 
    chown -R jesuruiz:ftp /srv/ftp && \ 
    chmod -R 755 /srv/ftp

# Creamos directorios para los sitios web y configuraciones
RUN mkdir -p /var/www/html/sitio1 /var/www/html/sitio2 

# Crear el certificado SSL autofirmado para proftpd
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/jesuruiz1.key -out /etc/ssl/certs/deaw.pem \
    -subj "/CN=Jesus Angel/O=Ruiz"

# Copiamos archivos al contenedor
COPY apache/index1.html apache/index2.html apache/sitio1.conf apache/sitio2.conf apache/sitio1.key apache/sitio1.cer /
COPY ftp/proftpd.conf /etc/proftpd/proftpd.conf
COPY ftp/tls.conf /etc/proftpd/
COPY ftp/modules.conf /etc/proftpd/
COPY ssh/sshd_config /etc/ssh/sshd_config
COPY apache/apache2.conf /etc/apache2/apache2.conf

# Movemos los archivos a sus ubicaciones adecuadas
RUN mv /index1.html /var/www/html/sitio1/index.html && \
    mv /index2.html /var/www/html/sitio2/index.html && \
    mv /sitio1.conf /etc/apache2/sites-available/sitio1.conf && \
    mv /sitio2.conf /etc/apache2/sites-available/sitio2.conf && \
    mv /sitio1.key /etc/ssl/private/sitio1.key && \
    mv /sitio1.cer /etc/ssl/certs/sitio1.cer

# Habilitamos los sitios y el módulo SSL en Apache
RUN a2ensite sitio1.conf && \
    a2ensite sitio2.conf && \
    a2enmod ssl

# Copiar el repositorio desde la etapa intermedia
COPY --from=intermediate /srv/ftp/proyecto /srv/ftp/proyecto

# Exponemos los puertos necesarios
EXPOSE 21 80 443 50000-50030 33

# Comando por defecto al iniciar el contenedor
CMD ["sh", "-c", "service proftpd start && service ssh start && apache2ctl -D FOREGROUND"]