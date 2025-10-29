# encoding: utf-8

##  Author: Spencer Caplan
##  CUNY Graduate Center

import sys, os, os.path
import numpy as np
import time
import argparse
import math
from statistics import mean
import random
from simulationhelpers import *
from collections import Counter as counter
from pathlib import Path

parent_dir = Path(__file__).resolve().parent.parent
sys.path.append(str(parent_dir))

from agents.tp_agent import TP_Agent
from agents.br_agent import BR_Agent
from agents.twothirds_agent import Twothirds_Agent
from agents.luce_agent import Luce_Agent

from aux.loadstandarddata import print_progress_bar


INPUT_FILENAME = ""
OUTPUT_FILENAME = ""
MEM_SIZE = 0
MEM_VARIANCE = 1
FIFO_REMOVAL = "FIFO"
UPDATE_RULE = "PENALIZE"
COL_SEP = "\t"


def config_runs(input_file):
	run_list = [[],[],[]] # initial empty container for 3 runs
	with open(input_file, 'r', newline="") as f:
		for line in f:
			row = line.strip().split(',')
			for i in range(3):
				run_list[i].append('a' if row[i]=='1' else 'b')
	return run_list



def parse_args_and_defaults(args: argparse.Namespace) -> None:
	global INPUT_FILENAME, MEM_SIZE, MEM_VARIANCE, OUTPUT_FILENAME, UPDATE_RULE

	if args.inputpath is None:
		raise Exception("Need to specify input file")
	else:
		INPUT_FILENAME = args.inputpath


	if args.M is None:
		raise Exception("Need to specify memory queue size")
	else:
		MEM_SIZE = args.M

	if args.V is None:
		raise Exception("Need to specify memory variance")
	else:
		MEM_VARIANCE = args.V

	if args.updaterule is None:
		raise Exception("Need to provide memory update procedure (BUFFER or PENALIZE)")
	elif args.updaterule not in ["BUFFER", "PENALIZE"]:
		raise Exception("Possible memory update procedures are BUFFER or PENALIZE")
	else:
		UPDATE_RULE = args.updaterule

	if args.outputfilered is None:
		raise Exception("Need to specify output file")
	else:
		OUTPUT_FILENAME = args.outputfilered



if __name__ == "__main__":

	random.seed()

	parser = argparse.ArgumentParser(description = "Mind Reading game simulation")
	parser.add_argument("--inputpath", help="Input file specifying game data", type=str)
	parser.add_argument("-M", help="Memory buffer size", type=int)
	parser.add_argument("-V", help="Memory variance in size", type=int)
	parser.add_argument("--updaterule", help="Memory addition procedure: penalized or buffer", type=str)
	parser.add_argument("--outputfilered", help="Output path for recording final red vs. blue selections", type=str)
	parse_args_and_defaults(args = parser.parse_args())

	run_list = config_runs(INPUT_FILENAME)

	CURR_PREPEND_STRING = " ".join([str(MEM_SIZE), str(MEM_VARIANCE), str(UPDATE_RULE), " -- "])

	totalmem = []
	total_results_dict = {"tp":[], "twothirds":[], "br":[], "luce":[]}
	SUBJECTS_PER_SIM = 200
	TOTAL_SIMULATIONS = 200

	with open(OUTPUT_FILENAME, 'a') as output_f:

		for sim_num in range(TOTAL_SIMULATIONS):
			# mem_size = [0] * SUBJECTS_PER_SIM # initial list
			results_curr_sim = {"tp":0, "twothirds":0, "br":0, "luce":0}
			# print(sim_num)
			for i in range(SUBJECTS_PER_SIM):
				curr_mem_size = max(int(np.random.normal(MEM_SIZE, MEM_VARIANCE)), 5) # min mem size is 5

				# randomly assign agent to sequence
				curr_seed = random.random()
				if curr_seed <= 0.3333:
					totalmem.append(1)
					curr_run = run_list[0]
				elif curr_seed <= 0.6667:
					totalmem.append(2)
					curr_run = run_list[1]
				else:
					totalmem.append(3)
					curr_run = run_list[2]

				# Initialize
				tp_agent = TP_Agent(i, curr_mem_size, ['old'], FIFO_REMOVAL, UPDATE_RULE)
				br_agent = BR_Agent(i, curr_mem_size, ['old'], FIFO_REMOVAL, UPDATE_RULE, 0.0)
				twothirds_agent = Twothirds_Agent(i, curr_mem_size, ['old'], FIFO_REMOVAL, UPDATE_RULE)
				luce_agent = Luce_Agent(i, curr_mem_size, ['old'], FIFO_REMOVAL, UPDATE_RULE)

				# Training phase
				for curr_round in curr_run:
					tp_agent.compare_add_name(tp_agent.get_name(), curr_round)
					br_agent.compare_add_name(br_agent.get_name(), curr_round)
					twothirds_agent.compare_add_name(twothirds_agent.get_name(), curr_round)
					luce_agent.compare_add_name(luce_agent.get_name(), curr_round)

				# Now do the test phase
				test_phase_count_tp = 1 if tp_agent.get_name() == 'a' else 0
				results_curr_sim["tp"] += test_phase_count_tp
				test_phase_count_br = 1 if br_agent.get_name() == 'a' else 0
				results_curr_sim["br"] += test_phase_count_br
				test_phase_count_luce = 1 if luce_agent.get_name() == 'a' else 0
				results_curr_sim["luce"] += test_phase_count_luce
				test_phase_count_twothirds = 1 if twothirds_agent.get_name() == 'a' else 0
				results_curr_sim["twothirds"] += test_phase_count_twothirds

			total_results_dict["tp"].append(results_curr_sim["tp"]/SUBJECTS_PER_SIM)
			total_results_dict["br"].append(results_curr_sim["br"]/SUBJECTS_PER_SIM)
			total_results_dict["luce"].append(results_curr_sim["luce"]/SUBJECTS_PER_SIM)
			total_results_dict["twothirds"].append(results_curr_sim["twothirds"]/SUBJECTS_PER_SIM)

			print_progress_bar(sim_num, TOTAL_SIMULATIONS, CURR_PREPEND_STRING)
		
		tpmean = np.mean(total_results_dict["tp"])
		tpstd = np.std(total_results_dict["tp"])
		brmean = np.mean(total_results_dict["br"])
		brstd = np.std(total_results_dict["br"])
		lucemean = np.mean(total_results_dict["luce"])
		lucestd = np.std(total_results_dict["luce"])
		twothirdsmean = np.mean(total_results_dict["twothirds"])
		twothirdsstd = np.std(total_results_dict["twothirds"])
		# print("TP", round(tpmean, 2), round(tpstd, 2))
		# print("BR", round(brmean, 2), round(brstd, 2))
		# print("TwoThirds", round(twothirdsmean, 2), round(twothirdsstd, 2))
		# print("Luce", round(lucemean, 2), round(lucestd, 2))

		OUTLIST = [Path(INPUT_FILENAME).stem,
				   str(np.round(tpmean,3)), str(np.round(tpstd,3)), 
				   str(np.round(brmean,3)), str(np.round(brstd,3)), 
				   str(np.round(twothirdsmean, 3)), str(np.round(twothirdsstd, 3)),
				   str(np.round(lucemean,3)), str(np.round(lucestd,3))]

		output_f.write(COL_SEP.join(OUTLIST))
		output_f.write("\n")
		# print("TP-23-PB-Luce", "%.3f" % abs(tpmean-emp),  "%.3f" % abs(twothirdsmean-emp),  "%.3f" % abs(brmean-emp),  "%.3f" % abs(lucemean-emp))


