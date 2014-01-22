#!/bin/sh

set -e
set -u
set -x

merge_from=trunk

base_dir="$(cd $(dirname "$0") && pwd)"
top_dir="${base_dir}/.."

mroonga_branch_dir="${top_dir}/mroonga"
bundled_mroonga_dir="${mroonga_branch_dir}/storage/mroonga"
bundled_groonga_dir="${bundled_mroonga_dir}/vendor/groonga"
bundled_groonga_normalizer_mysql_dir="${bundled_groonga_dir}/vendor/plugins/groonga-normalizer-mysql"

tmp_dir="${top_dir}/tmp"
tmp_install_dir="${top_dir}/tmp/local"

build_dir="${tmp_dir}/mroonga.build"

n_processors=1
case `uname` in
    Linux)
	n_processors="$(grep '^processor' /proc/cpuinfo | wc -l)"
	;;
    Darwin)
	n_processors="$(/usr/sbin/sysctl -n hw.ncpu)"
	;;
    *)
	:
	;;
esac

export PKG_CONFIG_PATH="${tmp_install_dir}/lib/pkgconfig"

setup_repositories()
{
    cd "${top_dir}"

    if [ ! -d ${merge_from} ]; then
	bzr init-repo .
	bzr branch lp:maria ${merge_from}
	rm -rf mroonga
    fi

    if [ ! -d mroonga ]; then
	bzr branch ${merge_from} mroonga
    fi
}

merge_mariadb()
{
    cd "${top_dir}/${merge_from}"
    bzr pull

    cd "${mroonga_branch_dir}"
    BUILD/cleanup
    bzr merge ../${merge_from}
    bzr commit -m "Merge from ${merge_from}" || true
}

update_mroonga()
{
    cd "${tmp_dir}"

    if [ ! -d mroonga ]; then
	git clone https://github.com/mroonga/mroonga
    fi

    cd mroonga
    git pull --rebase
    new_mroonga_version="$(git describe)"
    rm -rf "${bundled_mroonga_dir}"
    mkdir -p "${bundled_mroonga_dir}"
    cp -a * "${bundled_mroonga_dir}/"
    rm -rf "${bundled_mroonga_dir}/doc/"
    ruby "${base_dir}/flatten-test.rb" \
	"${bundled_mroonga_dir}/mysql-test/mroonga/storage"
    ruby "${base_dir}/flatten-test.rb" \
	"${bundled_mroonga_dir}/mysql-test/mroonga/wrapper"
}

update_groonga()
{
    cd "${tmp_dir}"

    if [ ! -d groonga ]; then
	git clone https://github.com/groonga/groonga
    fi

    cd groonga
    git pull --rebase
    new_groonga_version="$(git describe)"
    rm -rf "${bundled_groonga_dir}"
    mkdir -p "${bundled_groonga_dir}"
    cp -a * "${bundled_groonga_dir}/"
    rm -rf "${bundled_groonga_dir}/doc/"
    rm -rf "${bundled_groonga_dir}/test/"
}

update_groonga_normalizer_mysql()
{
    cd "${tmp_dir}"

    if [ ! -d groonga-normalizer-mysql ]; then
	git clone https://github.com/groonga/groonga-normalizer-mysql
    fi

    cd groonga-normalizer-mysql
    git pull --rebase
    new_groonga_normalizer_mysql_version="$(git describe)"
    rm -rf "${bundled_groonga_normalizer_mysql_dir}"
    mkdir -p "${bundled_groonga_normalizer_mysql_dir}"
    cp -a * "${bundled_groonga_normalizer_mysql_dir}/"
    rm -rf "${bundled_groonga_normalizer_mysql_dir}/test/"
}

update_bundles()
{
    mkdir -p "${tmp_dir}"
    update_mroonga
    update_groonga
    update_groonga_normalizer_mysql

    cd "${mroonga_branch_dir}"
    bzr add
    bzr commit \
	-m "Update Mroonga to the latest version on $(date --iso-8601=seconds)" || \
	true
}

build()
{
    cd "${mroonga_branch_dir}"
    ./BUILD/compile-amd64-valgrind-max
}

run_test()
{
    all_test_suite_names=""
    cd "${bundled_mroonga_dir}/mysql-test"
    for test_suite_name in \
	    $(find mroonga -type d -name 'include' '!' -prune -o \
			   -type d '!' -name 'mroonga' \
				   '!' -name 'include' \
				   '!' -name '[tr]'); do
	if [ -n "${all_test_suite_names}" ]; then
	    all_test_suite_names="${all_test_suite_names},"
	fi
	all_test_suite_names="${all_test_suite_names}${test_suite_name}"
    done
    cd -

    export GRN_PLUGINS_DIR="${bundled_groonga_normalizer_mysql_dir}"

    cd "${mroonga_branch_dir}/mysql-test"
    ./mysql-test-run \
	--valgrind \
	--valgrind-option=--show-reachable=yes \
	--valgrind-option=--gen-suppressions=all \
	--parallel=${n_processors} \
	--no-check-testcases \
	--retry=1 \
	--force \
	--suite="${all_test_suite_names}"
}

setup_repositories
merge_mariadb
update_bundles
build
run_test
