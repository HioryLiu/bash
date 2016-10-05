#!/bin/bash -eu

base_dir="/home/batch/ETL/"

tmp_dir=$base_dir"tmp/"
inbound_dir=$base_dir"inbound/"

if (( $# > 0 ));then  #参数传入，这里应该是 {{ds}},这里是否也可以用双括号？？
    start_dt=$1
    yyyymmdd=$(date '+%Y-%m-%d' -d "tomorrow $start_dt") #命令执行后的结果传给yymmdd
else
    yyyymmdd=$(date '+%Y-%m-%d')
fi

start_ts=$yyyymmdd"_01"
end_ts=$yyyymmdd"_02"

check_done_file="logstash_staging."$start_ts":??:??."$end_ts":??:??.sql.done" #这里的?是通配符

rc=$(ls -1 $inbound_dir$check_done_file|wc -l) #rc赋值，统计通配符文件名命中的文件数量，若不是一个，则返回错误码1
if (( $rc != 1 ));then
    exit 1
fi

# checksum between database
function checksum
{
    tmp_file=$tmp_dir/local_logstash_staging_count.$1
    mysql -Ns -uroot -pmeiyoumima123XXX! -h$1 <<EOF > $tmp_file 
select count(*) from dw_staging.logstash_staging
where src_create_timestamp >= adddate('$yyyymmdd', interval -1 day)
and src_create_timestamp < '$yyyymmdd';
EOF   # -Ns --skip-column-names 
}

checksum 127.0.0.1
checksum 10.45.13.172  #生成两个文件

report_cnt=`cat $tmp_dir/local_logstash_staging_count.127.0.0.1` #引用命令执行的结果
logdb_cnt=`cat $tmp_dir/local_logstash_staging_count.10.45.13.172`

echo "logdb: $logdb_cnt" 
echo "reportdb: $report_cnt"
if (( $report_cnt != $logdb_cnt ));then
    echo "count mismatch:"
    exit 2
fi
