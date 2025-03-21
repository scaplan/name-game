# encoding: utf-8

##  Author: Spencer Caplan
##  CUNY Graduate Center

import sys, os, os.path
import argparse
import copy
from math import log
from collections import defaultdict, Counter

# # Add parent directory to sys.path
# parent_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
# sys.path.insert(0, parent_dir)


USE_BR_MEM_INSTEAD_OF_TP = True
VERBOSE_MODE = True
NG_SOURCE_FILENAME = ""
OUTPUT_FILENAME = ""
OUTPUT_FILENAME_DISTRO = ""

STARTING_ROUND = 0

ratio_dict_total = defaultdict(int)
ratio_dict_br_hit = defaultdict(lambda: 0)
ratio_dict_br_miss = defaultdict(lambda: 0)

ratio_dict_total_2015 = defaultdict(int)
ratio_dict_br_hit_2015 = defaultdict(lambda: 0)
ratio_dict_br_miss_2015 = defaultdict(lambda: 0)

ratio_dict_total_2018 = defaultdict(int)
ratio_dict_br_hit_2018 = defaultdict(lambda: 0)
ratio_dict_br_miss_2018 = defaultdict(lambda: 0)



def consolidate_long_tail(inputdict, freq_cutoff, whitelistdict):
	total_count = sum(inputdict.values())
	inputdict_iterable_copy = copy.copy(inputdict)
	for name, count in inputdict_iterable_copy.items():
		prop = count/total_count
		if name != 'other' and name not in whitelistdict:
			if prop < freq_cutoff:
				inputdict['other'] += count
				del inputdict[name]
	return inputdict


def parse_args_and_defaults(args: argparse.Namespace) -> None:
	global VERBOSE_MODE, NG_SOURCE_FILENAME, OUTPUT_FILENAME, OUTPUT_FILENAME_DISTRO, STARTING_ROUND

	if args.datasourcefile is None:
		raise Exception("Need to specify path to empirical data")
		# targetFile = "model_emp_results_round_by_round_all.tsv"
	else:
		NG_SOURCE_FILENAME = args.datasourcefile

	if args.outputfile is None:
		raise Exception("Need to specify output path for main analysis file (proportion of top name usage)")
	else:
		OUTPUT_FILENAME = args.outputfile

	if args.outputfilefulldistro is None:
		raise Exception("Need to specify output path for main analysis file (full distribution)")
	else:
		OUTPUT_FILENAME_DISTRO = args.outputfilefulldistro

	if args.startinground is None:
		STARTING_ROUND = 0
		# defaults to including everything if not otherwise specified
	else:
		STARTING_ROUND = args.startinground

	if args.verboseprint:
		VERBOSE_MODE = True
	else:
		VERBOSE_MODE = False


def write_row(out_list, out_f):
	if VERBOSE_MODE:
		for item in out_list:
			print(f"{item: <18}", end='')
		# print(out_list)
		print("")
	out_string = ','.join(out_list)
	out_f.write(out_string+"\n")



if __name__ == '__main__':

	print("Checking output stochasticity at different name ratios... ", end="")

	parser = argparse.ArgumentParser(description = "Memory / naming sotachsticity")
	parser.add_argument("--datasourcefile", help="filename for source data", type=str)
	parser.add_argument("--outputfile", help="output filename for resulting analysis (proportion of top name usage)", type=str)
	parser.add_argument("--outputfilefulldistro", help="output filename for resulting analysis (full distribution of names in memory)", type=str)
	parser.add_argument("--startinground", help="specify which round to start including from -- useful for limiting to post-convergence trials only", type=int)
	parser.add_argument("--verboseprint", action=argparse.BooleanOptionalAction,
                        help="Print initial results to terminal (useful for debugging)")
	parse_args_and_defaults(args = parser.parse_args())

	MEMORY_INDEX = 21 if USE_BR_MEM_INSTEAD_OF_TP else 22
	round_dict = defaultdict(lambda: [])
	
	with open(NG_SOURCE_FILENAME, 'r') as f:
		next(f) #skip header
		with open(OUTPUT_FILENAME, 'w') as out_f:
			out_list = ['Ratio', 'SourcePaper', 'FromRound', 'top_name_entries', 'mem_entries', 'MemRatio_asProp', 'TP_cutoff',
						'Below_Above_TP', 'Trials', 'BR_Match', 'BR_Miss', 'Prop']
			write_row(out_list, out_f)

			for line in f:
				line = line.strip()
				curr_tokens = line.split("\t")
				sourcePaper = curr_tokens[1]
				isConfed = curr_tokens[6]
				memLimit = int(curr_tokens[2])
				roundNum = curr_tokens[7]
				outputName = curr_tokens[8]

				## Read the file into memory, but skip the confederate rows
				if isConfed == 'FALSE':
					if int(roundNum) >= STARTING_ROUND:
						if len(curr_tokens) > 22:
							round_dict[roundNum].append(curr_tokens)
							memory_names = curr_tokens[MEMORY_INDEX].split(';')
							num_mem_entries = len(memory_names)
							
							top_name_pairs = Counter(memory_names).most_common()
							top_name_pair = top_name_pairs.pop(0)
							top_name = top_name_pair[0]
							top_count = top_name_pair[1]
							ratio_key = str(top_count) + ":" + str(num_mem_entries)
							if top_name_pairs:
								second_name_pair = top_name_pairs.pop(0)
								second_count = second_name_pair[1]
								if second_count == top_count:
									# Skipping ties
									continue

							if sourcePaper == 'CB2015':
								ratio_dict_total_current = ratio_dict_total_2015
								ratio_dict_br_hit_current = ratio_dict_br_hit_2015
								ratio_dict_br_miss_current = ratio_dict_br_miss_2015
							elif sourcePaper == 'CBBB2018':
								ratio_dict_total_current = ratio_dict_total_2018
								ratio_dict_br_hit_current = ratio_dict_br_hit_2018
								ratio_dict_br_miss_current = ratio_dict_br_miss_2018
							else:
								raise Exception("SourcePaper column malformed!")

							ratio_dict_total[ratio_key] += 1
							ratio_dict_total_current[ratio_key] += 1
							if outputName == top_name:
								# print("BR hit! ", top_name, outputName)
								ratio_dict_br_hit[ratio_key] += 1
								ratio_dict_br_hit_current[ratio_key] += 1
							else:
								# print("BR miss ", top_name, outputName)
								ratio_dict_br_miss[ratio_key] += 1
								ratio_dict_br_miss_current[ratio_key] += 1


			# tabulating when memory is full
			for top_name_count in range(memLimit+1, 2, -1):
				ratio_key = str(top_name_count) + ':' + str(memLimit)
				memratioasprop = str(round(top_name_count / memLimit, 3))
				TP_cutoff = round(memLimit - (memLimit / log(memLimit)),2)
				Below_Above_TP = 'below' if top_name_count < TP_cutoff else 'above'

				if ratio_dict_total[ratio_key] > 0:
					hit_rate = str(round(ratio_dict_br_hit[ratio_key]/ratio_dict_total[ratio_key], 3))
					out_list = [ratio_key, 'BothCombined', str(STARTING_ROUND), str(top_name_count), str(memLimit), memratioasprop, str(TP_cutoff), Below_Above_TP , str(ratio_dict_total[ratio_key]), str(ratio_dict_br_hit[ratio_key]), str(ratio_dict_br_miss[ratio_key]), hit_rate]
					write_row(out_list, out_f)

				if ratio_dict_total_2015[ratio_key] > 0:
					hit_rate = str(round(ratio_dict_br_hit_2015[ratio_key]/ratio_dict_total_2015[ratio_key], 3))
					out_list = [ratio_key, 'CB2015', str(STARTING_ROUND), str(top_name_count), str(memLimit), memratioasprop, str(TP_cutoff), Below_Above_TP , str(ratio_dict_total_2015[ratio_key]), str(ratio_dict_br_hit_2015[ratio_key]), str(ratio_dict_br_miss_2015[ratio_key]), hit_rate]
					write_row(out_list, out_f)

				if ratio_dict_total_2018[ratio_key] > 0:
					hit_rate = str(round(ratio_dict_br_hit_2018[ratio_key]/ratio_dict_total_2018[ratio_key], 3))
					out_list = [ratio_key, 'CBBB2018', str(STARTING_ROUND), str(top_name_count), str(memLimit), memratioasprop, str(TP_cutoff), Below_Above_TP , str(ratio_dict_total_2018[ratio_key]), str(ratio_dict_br_hit_2018[ratio_key]), str(ratio_dict_br_miss_2018[ratio_key]), hit_rate]
					write_row(out_list, out_f)

			# tabulating just the early rounds, below the TP threshold
			for early_round_number in range(4,memLimit):
				for top_name_count in range(early_round_number, 3, -1):
					ratio_key = str(top_name_count) + ':' + str(early_round_number)
					memratioasprop = str(round(top_name_count / early_round_number, 3))
					TP_cutoff = round(early_round_number - (early_round_number / log(early_round_number)),2)
					Below_Above_TP = 'below' if top_name_count < TP_cutoff else 'above'
					if ratio_dict_total[ratio_key] > 0 and Below_Above_TP == 'below':
						hit_rate = str(round(ratio_dict_br_hit[ratio_key]/ratio_dict_total[ratio_key], 3))
						out_list = [ratio_key, 'BothCombined', str(STARTING_ROUND), str(top_name_count), str(early_round_number), memratioasprop, str(TP_cutoff), Below_Above_TP , str(ratio_dict_total[ratio_key]), str(ratio_dict_br_hit[ratio_key]), str(ratio_dict_br_miss[ratio_key]), hit_rate]
						write_row(out_list, out_f)




	"""
	Check distribution of memory names and output names by round
	"""
	if STARTING_ROUND == 0:
		print("Checking similarity between distribution of memory slots and round output...", end="")
		with open(OUTPUT_FILENAME_DISTRO, 'w') as output_f_fulldistro:
			out_list = ['SourcePaper', 'Round', 'Name', 'NameNum', 'ProductionProp', 'MemoryProp']
			write_row(out_list, output_f_fulldistro)

			nameNumWords = ['Top', 'Second', 'Third', 'Fourth', 'Fifth']

			for roundNum in range(2, 26):
				for curr_paper in ["CB2015", "CBBB2018"]:
					curr_round = round_dict.get(str(roundNum))
					round_print_str = "ROUND NUM " + str(roundNum)
					memory_name_dict = defaultdict(lambda: 0)
					output_name_dict = defaultdict(lambda: 0)

					for row in curr_round:
						memory_names = row[MEMORY_INDEX].split(';')
						output_name = row[8]
						row_paper = row[1]
						if row_paper == curr_paper:
							output_name_dict[output_name] += 1
							for name in memory_names:
								if name != 'na' and len(name) > 0:
									memory_name_dict[name] += 1

					total_name_count = sum(memory_name_dict.values())
					total_output_count = sum(output_name_dict.values())
					output_name_dict = consolidate_long_tail(output_name_dict, 0.05, {})
					memory_name_dict = consolidate_long_tail(memory_name_dict, 0.05, output_name_dict)

					produced_sort_orders = sorted(output_name_dict.items(), key=lambda x: x[1], reverse=True)
					namenumcounter = 0
					for pair in produced_sort_orders:
						name = pair[0]
						produce_prop = round(pair[1]/total_output_count, 2)
						if name in memory_name_dict:
							memory_prop = round(memory_name_dict.get(name)/total_name_count, 2)
						else:
							memory_prop = '0.00'

						if name == 'other':
							nameNum = 'other'
						else:
							if namenumcounter < len(nameNumWords):
								nameNum = nameNumWords[namenumcounter]
								namenumcounter += 1
							else:
								nameNum = 'drop'
						out_list = [curr_paper, str(roundNum), name, nameNum, str(produce_prop), str(memory_prop)]
						write_row(out_list, output_f_fulldistro)


	print("Done :) ", end="")




