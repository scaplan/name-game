# encoding: utf-8

def load_empirical_data_into_memory(inputfilename):
	"""
	return a dict which maps from experimentstring to a list of rows (lists of data strings)
	along with a list containing the keyset
	"""

	COL_SEP = "\t"

	expid_to_rows_dict = {}
	expid_key_list = []

	with open(inputfilename, 'r') as inputfile:
		next(inputfile) # skip header line

		for line in inputfile:
			line = line.strip()
			curr_tokens = line.split(COL_SEP)
			curr_exp_id = curr_tokens[1]

			if curr_exp_id in expid_to_rows_dict:
				curr_exp_rows = expid_to_rows_dict.get(curr_exp_id)
			else:
				curr_exp_rows = []
				expid_key_list.append(curr_exp_id)

			curr_exp_rows.append(curr_tokens)
			expid_to_rows_dict[curr_exp_id] = curr_exp_rows

		inputfile.close()

	return expid_to_rows_dict, expid_key_list


def filter_add_name_to_total_data(name, name_list, name_dict):
	noresponseset = {"response_not_given", "na"}
	if len(name) > 0 and name not in noresponseset:
		name_list.append(name)
		if name in name_dict:
			name_dict[name] = name_dict.get(name) + 1
		else:
			name_dict[name] = 1


def get_initial_name_distro(curr_data):
	"""
	Here just look at the first rounds
	Count up names and append to list
	Also add to dict with counts for easy debugging
	Future sampling can then be random selection from that list
	"""

	first_round_names_list = []
	first_round_names_dict = {}

	for curr_row in curr_data:
		speaker_A_curr_output = curr_row[6]
		speaker_A_round_number = int(curr_row[5])
		speaker_A_isconfed = curr_row[7]

		speaker_B_curr_output = curr_row[10]
		speaker_B_round_number = int(curr_row[9])
		speaker_B_isconfed = curr_row[11]
		if speaker_A_round_number == 1 and speaker_A_isconfed == "FALSE":
			filter_add_name_to_total_data(speaker_A_curr_output, first_round_names_list, first_round_names_dict)
		if speaker_B_round_number == 1 and speaker_B_isconfed == "FALSE":
			filter_add_name_to_total_data(speaker_B_curr_output, first_round_names_list, first_round_names_dict)

		names_sorted_keys = sorted(first_round_names_dict, key=first_round_names_dict.get, reverse=True)

	return (first_round_names_list, first_round_names_dict)



def print_progress_bar(curr_iter, total_iters, prefix = ''):
	"""
	Printing progress par...
	Adapted from: https://stackoverflow.com/questions/3173320/text-progress-bar-in-terminal-with-block-characters
	"""
	suffix = ''
	decimals = 1
	length = 60
	fill = '█'
	printEnd = "\r"

	percent = ("{0:." + str(decimals) + "f}").format(100 * (curr_iter / float(total_iters)))
	filledLength = int(length * curr_iter // total_iters)
	bar = fill * filledLength + '-' * (length - filledLength)
	print(f'\r {prefix} |{bar}| {percent}% {suffix}', end = printEnd)
	# Print New Line on Complete
	if curr_iter == total_iters: 
		print()


