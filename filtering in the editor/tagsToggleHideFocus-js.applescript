function run() {
	/*jshint multistr:true */
	var dctOpt = {
		title: "View/hide tags in FT document",
		ver: "0.5",
		description: "Hides or focuses on particular tags.\
					  and shows active node paths with counts of hidden\
					  and visible tags of each kind.",
		author: "RobTrew",
		license: "MIT",
		site: "https://github.com/RobTrew/txtquery-tools"
	};

	function visibleTags(ed) {
		var oTree = ed.tree(),
			lstTags = oTree.tags().sort(),
			lstNodes, lstVisible = [],
			strTag, j, lngNodes,
			lngHidden = 0,
			lngShown = 0;

		for (var lng = lstTags.length, i = 0; i < lng; i++) {
			strTag = lstTags[i];
			lstNodes = oTree.evaluateNodePath('//@' + strTag);
			lngNodes = lstNodes.length;

			lngHidden = 0;
			for (j = lngNodes; j--;) {
				if (ed.nodeIsHiddenInFold(lstNodes[j])) lngHidden += 1;
			}
			lstVisible.push(
				lngHidden ?
				('@' + strTag + '\t' + (lngNodes - lngHidden) + '/' + lngNodes) + ' → focus' :
				('@' + strTag + '\t' + lngNodes) + ' → hide'
			);

		}
		return lstVisible;
	}

	function updateView(ed, opt) {

		function updatedPath(strOldPath, lstChoice) {
			var lstParts, lstScore, lstShow = [],
				lstHide = [],
				strPath = '',
				strShow, strHide,
				lngVisible, lngTotal,
				lng = lstChoice.length,
				i;

			// Partial || None -- > Focus
			// All -- > Hide
			for (i = lng; i--;) {
				lstParts = lstChoice[i].split('\t');

				if ('SHOW ALL' === lstParts[0]) {
					return '///*';
				}

				lstScore = lstParts[1].split('/');
				lngVisible = lstScore[0];
				lngTotal = lstScore[1];

				if (lngVisible < lngTotal) lstShow.push(lstParts[0]);
				else lstHide.push(lstParts[0]);
			}

			lng = lstShow.length;
			if (lng) strPath = '//' + ((lng > 1) ?
				'(' + lstShow.join(' or ') + ')' :
				lstShow[0]);

			lng = lstHide.length;
			if (lng) {
				strHide =
					(lng > 1) ? '(' + lstHide.join(' or ') + ')' :
					lstHide[0];

				strPath = strPath ?
					(strPath + ' except //' + strHide) :
					('//not ' + strHide);
			}
			return strPath;
		}

		var strNewPath = updatedPath(opt.oldPath, opt.choice);
		ed.setNodePath(strNewPath);
		return strNewPath;
	}

	function docPath(ed) {
		return ed.nodePath().toString();
	}

	var appFT=Application("FoldingText"),
		docsFT = appFT.documents(),
		lngDocs = docsFT.length,
		oDoc = lngDocs ? docsFT[0] : null,
		strPath, strNewPath = '///*',
		lstHide = [],
		lstFocus = [],
		lstSelected = [],
		lstTagSet = [],
		varChoice = true,
		lngTagSet, i;

	if (lngDocs) {
		lstTagSet = oDoc.evaluate({
			script: visibleTags.toString()
		});
		lstTagSet.push('SHOW ALL\t');
		strPath = oDoc.evaluate({
			script: docPath.toString()
		});

		appFT.includeStandardAdditions = true;
		lngTagSet = lstTagSet.length;
		if (lngTagSet) {
			lstSelected = lstTagSet[lngTagSet - 1];
			while (varChoice) {
				appFT.activate();
				varChoice = appFT.chooseFromList(lstTagSet, {
					withTitle: dctOpt.title + ' ' + dctOpt.ver,
					withPrompt: 'active node path:\n\n' + strPath +
						'\n\n' + '( visible / total ) → action\n\n' +
						'⌘-click for multiple tag(s):',
					defaultItems: lstSelected,
					multipleSelectionsAllowed: true
				});

				if (varChoice) {
					// record indices of choices
					lstSelected = [];
					for (i = varChoice.length; i--;) {
						lstSelected.push(lstTagSet.indexOf(varChoice[i]));
					}

					// Get a new path
					strNewPath = oDoc.evaluate({
						script: updateView.toString(),
						withOptions: {
							oldPath: strPath,
							choice: varChoice
						}
					});
					// Update the list of tag visibilities
					strPath = strNewPath;
					lstTagSet = oDoc.evaluate({
						script: visibleTags.toString()
					});
					lstTagSet.push('SHOW ALL\t');

					// and create a list of default selections
					// from the indices of the previous choices 
					for (i = lstSelected.length; i--;) {
						lstSelected[i] = lstTagSet[lstSelected[i]];
					}
				}
			}
		}
	}

	return strNewPath;
}