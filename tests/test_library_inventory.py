#!/usr/bin/env python3
"""Metadata-only inventory contracts; no matrix/distance generation or solver."""
import copy
import csv
import hashlib
import io
import json
from pathlib import Path
import sys
import unittest

ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts'))
import library_inventory as li


def oid(text):return hashlib.sha1(text.encode()).hexdigest()


def manifest(claim='estimate 4',lb='',ub=''):
    fields=['stem','family','n','k','claimed_d','smoke_60s_lb','smoke_60s_ub','smoke_60s_status']
    row=dict(stem='HGP_7_1_unknown',family='HGP',n='7',k='1',claimed_d=claim,
             smoke_60s_lb=lb,smoke_60s_ub=ub,smoke_60s_status='')
    out=io.StringIO();w=csv.DictWriter(out,fieldnames=fields,lineterminator='\n');w.writeheader();w.writerow(row)
    return out.getvalue()


class Reader:
    def __init__(self,refs):
        self.trees={};self.texts={}
        for ref in refs:
            sha=ref['sha'];self.trees[sha]={li.BASE+'HGP_7_1_unknown_'+k+'.txt':oid(k) for k in li.KINDS}
            self.texts[sha]={li.BASE+'MANIFEST.csv':manifest()}
    def text(self,sha,path):return self.texts[sha][path]
    def tree(self,sha):return self.trees[sha]


class Inventory(unittest.TestCase):
    def setUp(self):
        self.config=dict(schema_version=1,scope='fixture only; metadata, not actual code',
            main=dict(branch='main',sha='1'*40),
            libraries=[dict(branch='library-a',sha='2'*40),dict(branch='library-b',sha='3'*40)],
            scientific_holds=[dict(issue=200,status='SOURCE_DIMENSION_HOLD',decision='PI pending')])
        self.refs=[self.config['main']]+self.config['libraries'];self.reader=Reader(self.refs)
    def run_index(self):return li.build(self.config,self.reader)
    def queue(self,content,runner='same',path='optimization/experiments/GH-999/runner/jobs.jsonl',refs=None):
        for ref in self.refs if refs is None else refs:
            sha=ref['sha'];self.reader.trees[sha][path]=oid(content);self.reader.texts[sha][path]=content
            self.reader.trees[sha][str(Path(path).with_name('run_serial.py'))]=oid(runner)

    def test_repeated_memberships_are_not_new_stems(self):
        r=self.run_index();self.assertEqual(r['summary']['manifest_memberships'],3)
        self.assertEqual(r['summary']['distinct_stems'],1);self.assertEqual(r['summary']['repeated_stem_memberships'],2)
        self.assertEqual(r['summary']['stored_four_file_versions'],1)
        self.assertEqual(len(r['codes'][0]['versions'][0]['observations'][0]['locations']),3)

    def test_raw_claim_versions_and_empty_bounds_preserved(self):
        self.reader.texts['2'*40][li.BASE+'MANIFEST.csv']=manifest('<= 4',lb='2',ub='7')
        r=self.run_index();obs=r['codes'][0]['versions'][0]['observations']
        self.assertEqual(len(obs),2);claims={o['manifest']['claimed_d']:o['manifest'] for o in obs}
        self.assertEqual(claims['estimate 4']['smoke_60s_lb'],'')
        self.assertEqual(claims['<= 4']['smoke_60s_ub'],'7')
        self.assertNotIn('scientific_status',r['codes'][0])

    def test_changed_four_file_version_stays_visible(self):
        self.reader.trees['3'*40][li.BASE+'HGP_7_1_unknown_Gz.txt']=oid('different logical basis')
        r=self.run_index();self.assertEqual(r['summary']['distinct_stems'],1)
        self.assertEqual(r['summary']['stored_four_file_versions'],2)

    def test_identical_files_with_different_stems_are_aliases(self):
        sha='2'*40
        for k in li.KINDS:self.reader.trees[sha][li.BASE+'BB_7_1_unknown_'+k+'.txt']=oid(k)
        text=self.reader.texts[sha][li.BASE+'MANIFEST.csv']
        row=text.splitlines()[1].replace('HGP_7_1_unknown,HGP','BB_7_1_unknown,BB')
        self.reader.texts[sha][li.BASE+'MANIFEST.csv']=text+row+'\n'
        r=self.run_index();self.assertEqual(r['summary']['distinct_stems'],2)
        self.assertEqual(r['summary']['stored_four_file_versions'],1)
        self.assertEqual(r['identical_file_set_aliases'][0]['stems'],['BB_7_1_unknown','HGP_7_1_unknown'])

    def test_incomplete_flat_input_fails(self):
        del self.reader.trees['2'*40][li.BASE+'HGP_7_1_unknown_Gx.txt']
        with self.assertRaisesRegex(ValueError,'incomplete four-file'):self.run_index()

    def test_unregistered_flat_input_fails(self):
        for k in li.KINDS:self.reader.trees['2'*40][li.BASE+'HGP_13_1_unknown_'+k+'.txt']=oid('extra'+k)
        with self.assertRaisesRegex(ValueError,'manifest/flat'):self.run_index()

    def test_held_partial_input_excluded_from_stem_and_peer_counts(self):
        for k in ['Hx','Hz']:self.reader.trees['2'*40][li.BASE+'quarantine/GH-200/MM_7_1_unknown_'+k+'.txt']=oid('held'+k)
        r=self.run_index();self.assertEqual(r['summary']['distinct_stems'],1)
        self.assertEqual(r['summary']['quarantined_candidate_versions'],1)
        self.assertEqual(r['quarantined'][0]['missing_kinds'],['Gx','Gz'])
        self.assertEqual(r['same_n_k_review_groups'],[])
        self.assertIn('SOURCE_DIMENSION_HOLD',li.markdown(r))

    def test_main_tier_peers_in_review_groups(self):
        for k in li.KINDS:self.reader.trees['1'*40]['data/matrices/tier0/GB_7_1_3_'+k+'.txt']=oid('tier'+k)
        r=self.run_index();self.assertEqual(r['summary']['main_tiered_inputs'],1)
        self.assertEqual(r['same_n_k_review_groups'][0]['stems'],['untiered:HGP_7_1_unknown','tier0:GB_7_1_3'])
        self.assertEqual(r['same_n_k_review_groups'][0]['status'],'REVIEW_GROUP_ONLY_NOT_EQUIVALENCE_PROOF')

    def test_same_queue_and_runner_not_repeated(self):
        self.queue(json.dumps(dict(id='a',limit=21600))+'\n')
        r=self.run_index();self.assertEqual(r['summary']['retained_queue_versions'],1)
        self.assertEqual(r['queue_versions'][0]['declared_cpu_limit_sum_seconds'],21600)
        self.assertEqual(len(r['queue_versions'][0]['locations']),3)

    def test_changed_runner_is_a_different_queue_package(self):
        self.queue('{"id":"a","limit":21600}\n');self.queue('{"id":"a","limit":21600}\n',runner='changed',refs=self.refs[1:2])
        self.assertEqual(self.run_index()['summary']['retained_queue_versions'],2)

    def test_unknown_limits_are_not_synthesized(self):
        self.queue('{"id":"a","cpu_limit":21600}\n')
        r=self.run_index();self.assertIsNone(r['queue_versions'][0]['declared_cpu_limit_sum_seconds'])
        self.assertIn('unknown',li.markdown(r))

    def test_invalid_limit_not_counted_as_one_second(self):
        self.queue('{"id":"a","limit":true}\n')
        self.assertIsNone(self.run_index()['queue_versions'][0]['declared_cpu_limit_sum_seconds'])

    def test_empty_queue(self):
        self.queue('');q=self.run_index()['queue_versions'][0]
        self.assertEqual(q['jobs'],[]);self.assertEqual(q['declared_cpu_limit_sum_seconds'],0)

    def test_legacy_job_files_are_deduplicated_but_not_parsed(self):
        self.queue('opaque historical format',path='optimization/experiments/GH-999/S1/runner/jobs_cc.jsonl')
        r=self.run_index();self.assertEqual(r['summary']['retained_queue_versions'],0)
        self.assertEqual(r['summary']['unparsed_job_files'],1)
        self.assertEqual(len(r['unparsed_job_files'][0]['locations']),3)

    def test_malformed_canonical_queue_fails(self):
        self.queue('not JSON')
        with self.assertRaises(json.JSONDecodeError):self.run_index()

    def test_wrong_stem_parameters_fail(self):
        self.reader.texts['2'*40][li.BASE+'MANIFEST.csv']=manifest().replace('HGP_7_1_unknown,HGP,7,1','HGP_7_1_unknown,HGP,7,2')
        with self.assertRaisesRegex(ValueError,'parameter mismatch'):self.run_index()

    def test_bad_ref_or_duplicate_pin_fails(self):
        self.config['libraries'][0]['sha']='main'
        with self.assertRaisesRegex(ValueError,'immutable SHA'):self.run_index()
        self.config['libraries'][0]['sha']='2'*40;self.config['libraries'][0]['branch']='main'
        with self.assertRaisesRegex(ValueError,'duplicate branch'):self.run_index()

    def test_main_object_inventory_in_real_repository(self):
        config=dict(schema_version=1,scope='test main metadata only',main=dict(branch='main',sha='6083e662c621f3b66defd434cfae31a028d483c4'),libraries=[])
        r=li.build(config,li.GitReader(ROOT));self.assertEqual(r['summary']['main_tiered_inputs'],51)
        self.assertEqual(r['summary']['main_untiered_rows'],24)

    def test_deterministic_no_mutation(self):
        before=copy.deepcopy(self.reader.trees)
        self.assertEqual(json.dumps(self.run_index(),sort_keys=True),json.dumps(self.run_index(),sort_keys=True))
        self.assertEqual(before,self.reader.trees)


if __name__=='__main__':unittest.main()
