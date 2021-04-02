ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX

FROM ${PREFIX}/crunchy-base:${BASEOS}-${PG_FULL}-${BASEVER}
# crunchy-postgres image runs as USER 26, switch back to install packages
USER 0

# ===== Early lines ordered for leveraging cache, reorder carefully =====
# For RHEL8 all arguments used in main code has to be specified after FROM
ARG BASEOS
ARG PG_FULL
ARG DFSET
ARG PACKAGER
ARG PG_MAJOR

# Preserving PGVERSION out of paranoia
ENV PGROOT="/usr/pgsql-${PG_MAJOR}" PGVERSION="${PG_MAJOR}"

# ===== Steps unique to this image after here =====
ARG PATRONI_VER


LABEL name="postgres-ha" \
	summary="PostgreSQL ${PG_FULL} with Patroni" \
	description="Used for the deployment and management of highly-available PostgreSQL clusters using Patroni." \
	io.k8s.description="Crunchy PostgreSQL optimized for high-availability (HA)" \
	io.k8s.display-name="Crunchy PostgreSQL - HA Optimized" \
	io.openshift.tags="postgresql,postgres,postgis,sql,nosql,database,ha,crunchy"

RUN ${PACKAGER} -y install \
		--setopt=skip_missing_names_on_install=False \
		unzip file rsync perl \
		python3-devel \
		python3-pip \
		python3-psutil \
		python3-psycopg2 \
	&& ${PACKAGER} -y clean all

ARG S3_REPO_RPM=https://postgres.s3.didiyunapi.com/postgres-server-13.1-1.el7.centos.x86_64.rpm
RUN ${PACKAGER} -y localinstall ${S3_REPO_RPM}

# install patroni for Kube
RUN pip3 install --upgrade python-dateutil \
	&& pip3 install patroni[kubernetes]=="${PATRONI_VER}" -i https://pypi.doubanio.com/simple/

ENV PATH="${PGROOT}/bin:${PATH}"

RUN mkdir -p /opt/crunchy/bin /opt/crunchy/conf /pgdata /pgwal /pgconf /recover /backrestrepo /tablespaces

# Adjust ownership for the folders to be the "postgres" user and allow the group
# permissions to match the user ones EXCEPT for the /tablespaces folder, which
# will only have permissions on the user
RUN chown -R postgres:postgres /opt/crunchy \
		/pgdata /pgwal /pgconf /recover /backrestrepo /tablespaces &&  \
	chmod -R g=u /opt/crunchy  \
		/pgdata /pgwal /pgconf /recover /backrestrepo /tablespaces

# open up the postgres port
EXPOSE 5432

ADD bin/postgres_common /opt/crunchy/bin
ADD bin/common /opt/crunchy/bin
ADD conf/postgres_common /opt/crunchy/conf
ADD tools/pgmonitor/exporter/postgres /opt/crunchy/bin/modules/pgexporter

RUN chmod g=u /etc/passwd && \
	chmod g=u /etc/group

RUN mkdir /.ssh && chown 26:0 /.ssh && chmod g+rwx /.ssh && rm -f /run/nologin

ADD bin/postgres-ha /opt/crunchy/bin/postgres-ha
ADD conf/postgres-ha /opt/crunchy/conf/postgres-ha

ADD yq /opt/crunchy/bin
RUN chmod +x /opt/crunchy/bin/yq

RUN yum install -y lz4-devel libzstd-devel
RUN cd /tmp && git clone https://git.xiaojukeji.com/yangjianghua/citus.git && cd citus && git checkout master && export PG_CONFIG=/usr/pgsql-${PG_MAJOR}/bin/pg_config && ./configure && make install

# The VOLUME directive must appear after all RUN directives to ensure the proper
# volume permissions are applied when building the image
VOLUME ["/pgdata", "/pgwal", "/pgconf", "/backrestrepo", "/sshd"]

ENTRYPOINT ["/opt/crunchy/bin/postgres-ha/bootstrap-postgres-ha.sh"]

USER 26

CMD ["/usr/local/bin/patroni"]
