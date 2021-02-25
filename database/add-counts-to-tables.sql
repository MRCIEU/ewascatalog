-- p-value threshold for CpG site associations is < 1e-4
select @threshold := 0.0001;

-- If 'alter table' hangs, there may be a
-- process preventing changes to the database.
-- Verify this with 'show processlist'
-- and 'kill' any non-root processes by 'Id' value.

drop function if exists column_exists;

delimiter $$  
create function column_exists(
  tname VARCHAR(64),
  cname VARCHAR(64)
)
  returns boolean
  reads sql data
  begin
    return 0 < (select count(*) from information_schema.columns
                where table_schema=schema()
		and table_name=tname
		and column_name=cname);
  end $$
delimiter ;

drop procedure if exists drop_column_if_exists;

delimiter $$
create procedure drop_column_if_exists(
  tname VARCHAR(64),
  cname VARCHAR(64)
)
  begin
    if column_exists(tname, cname)
    then 
      set @drop_column_if_exists = concat('alter table ', tname, ' drop column ', cname);
      prepare drop_query from @drop_column_if_exists;
      execute drop_query;
    end if;
  end $$
delimiter ;

-- ----------------------
-- studies

CALL drop_column_if_exists('studies','assocs');

alter table studies
  add column assocs int;

update studies left join (
  select study_id, count(distinct(cpg)) as n
  from results
  where p < @threshold
  group by study_id
) counts on counts.study_id = studies.study_id
set studies.assocs = counts.n;

-- ----------------------
-- genes

CALL drop_column_if_exists('genes','assocs');

alter table genes
  add column assocs int;

update genes left join (
  select gene, count(distinct study_id,cpg) as n
  from results
  where p < @threshold
  group by gene
) counts on counts.gene = genes.gene
set genes.assocs = counts.n;

CALL drop_column_if_exists('genes','sites');

alter table genes
  add column sites int;

update genes left join (
  select gene, count(distinct cpg) as n
  from cpgs
  group by gene
) counts on counts.gene = genes.gene
set genes.sites = counts.n;

-- ----------------------
-- cpg sites

CALL drop_column_if_exists('cpgs','assocs');

alter table cpgs
  add column assocs int default 0; -- 1 minute!

drop table if exists cpg_counts;

create temporary table cpg_counts as
select cpg, count(distinct study_id) as n
from results
where p < @threshold
group by cpg;

alter table cpg_counts add primary key (cpg);
-- mysql doesn't do this implicitly, speeds update a bit

-- describe/explain
update cpgs
left join cpg_counts
on cpg_counts.cpg = cpgs.cpg
set cpgs.assocs = cpg_counts.n; -- 8 minutes!


-- ----------------------
-- authors

drop table if exists authors;

create table authors as
  select author, count(*) as assocs from
    (select distinct author, studies.study_id, cpg
      from results
      join studies on results.study_id = studies.study_id
      where p < @threshold) temp
    group by author;
    
alter table authors
  add column pubs int;

update authors left join (
  select author, count(distinct pmid) as n
  from studies
  group by author
) counts on counts.author = authors.author
set authors.pubs = counts.n;



-- ----------------------
-- traits

drop table if exists traits;

create table traits as
  select trait, count(*) as assocs
  from (select distinct trait,studies.study_id,cpg
        from results
	join studies on results.study_id = studies.study_id
	where p < @threshold) temp
  group by trait;

alter table traits
  add column pubs int;

update traits left join (
  select trait, count(distinct pmid) as n
  from studies
  group by trait
) counts on counts.trait = traits.trait
set traits.pubs = counts.n;

-- ----------------------
-- efo_terms

-- sigh, we have to deal with comma-separated lists, grrrrr
drop table if exists efo_tmp;

create temporary table efo_tmp as (
  select study_id, efo as efo_list,
  char_length(efo)-char_length(replace(efo,",",""))+1 as n
  from studies
);

/*
select @max_terms := max(n) from efo_tmp;
*/

-- create sequence assuming that no study has >10 efo terms
drop table if exists seq_tmp;

create temporary table seq_tmp as 
  select 1 as i
  union select 2 as i
  union select 3 as i
  union select 4 as i
  union select 5 as i
  union select 6 as i
  union select 7 as i
  union select 8 as i
  union select 9 as i
  union select 10 as i;

drop table if exists study_efo;

create table study_efo as
  select
    study_id,
    replace(substring_index(substring_index(efo_list,',',i),',',-1), ' ', '') as efo
  from efo_tmp join seq_tmp on efo_tmp.n >= seq_tmp.i;

drop table if exists efo_terms;

create table efo_terms as
  select efo, count(*) as assocs
  from (select distinct efo,results.study_id,cpg
        from results
	join study_efo on study_efo.study_id = results.study_id
  	where p < @threshold and efo <> "NA") temp
  group by efo;

alter table efo_terms
  add column pubs int;

update efo_terms left join (
  select study_efo.efo as efo, count(distinct pmid) as n
  from study_efo
  join studies on study_efo.study_id = studies.study_id
  group by study_efo.efo
) counts on counts.efo = efo_terms.efo
set efo_terms.pubs = counts.n;
