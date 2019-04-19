/**
 * In the potentially deeply-nested object o, for all values of type
 * valueType equal to origValue, replace them with newValue. If
 * newValue is undefined, delete the keys
 */
const deepReplace =
    (obj, valueType, origValue, newValue, deleteTheseKeys=[]) => {

  if (!obj || !(obj instanceof Object)) {
    return;
  }

  if (!(obj instanceof Array)) {
    Object.keys(obj).forEach((key) => {
      const nestedObj = obj[key];
      if (typeof nestedObj === valueType && nestedObj === origValue) {
        if (newValue === undefined) {
          deleteTheseKeys.push(key);
        } else {
          obj[key] = newValue;
        }
      } else if (nestedObj instanceof Object) {
        deepReplace(nestedObj, valueType, origValue, newValue);
      }
    });
    deleteTheseKeys.forEach((key) => {
      delete obj[key];
    });
  } else {
    obj.forEach((nestedObj, idx, currArr) => {
      if (typeof nestedObj === valueType && nestedObj === origValue) {
        if (newValue === undefined) {
          deleteTheseKeys.push(idx);
        } else {
          currArr[idx] = newValue;
        }
      } else if (nestedObj instanceof Object) {
        deepReplace(nestedObj, valueType, origValue, newValue);
      }
    });
    while (deleteTheseKeys.length > 0) {
      const idx = deleteTheseKeys.pop();
      obj.splice(idx, 1);
    }
  }
};

// TODO: write debugLevel handling
const cloudwatchLog = (msg, debugLevel = 0) => {
  if (process.env.LOG_DEBUG_STATEMENTS) {
    console.log(msg);
  }
};

const getRandomInt = maximum => {
  return Math.floor(Math.random() * Math.floor(maximum));
};

const multiToSingleLine = str => {
  return str.replace(/\n/g, '').replace(/(    )+/g, '');
};

const listToSet = lst => {
  const rtnSet = {};
  lst.forEach(elem => {
    if (rtnSet[elem] === undefined) {
      rtnSet[elem] = true;
    }
  });
  return Object.keys(rtnSet);
};

const subset = (lst1, lst2) => {
  for (var i = 0; i < lst1.length; i++) {
    if (!lst2.includes(lst1[i])) {
      return false;
    }
  }
  return true;
};

const setEqual = (lst1, lst2) => {
  const set1 = listToSet(lst1);
  const set2 = listToSet(lst2);
  if (set1.length !== set2.length) {
    return false;
  }
  return subset(set1, set2) && subset(set2, set1);
};

const listEqual = (lst1, lst2) => {
  if (lst1.length !== lst2.length) {
    return false;
  }
  for (var i = 0; i < lst1.length; i++) {
    if (lst1[i] !== lst2[i]) {
      return false;
    }
  }
  return true;
};

// SHALLOW equality test
const dictEqual = (d1, d2, eq) => {
  const d1Keys = Object.keys(d1);
  const d2Keys = Object.keys(d2);
  if (!setEqual(d1Keys, d2Keys)) {
    return false;
  }
  for (var i = 0; i < d1Keys.length; i++) {
    const currKey = d1Keys[i];
    if (eq) {  // if equality func is given, prefer that to ===
      if (!eq(d1[currKey], d2[currKey])) {
        return false;
      }
    } else {  // otherwise just use ===
      if (d1[currKey] !== d2[currKey]) {
        return false;
      }
    }
  }
  return true;
};

const range = (lower, upper) => {
  if (upper === null || upper === undefined) {
    return [...Array(lower).keys()];
  }
  return [...Array(upper).keys()].slice(lower);
};

const exists = obj => obj !== null && obj !== undefined;

exports.deepReplace = deepReplace;
exports.cloudwatchLog = cloudwatchLog;
exports.getRandomInt = getRandomInt;
exports.multiToSingleLine = multiToSingleLine;
exports.listToSet = listToSet;
exports.subset = subset;
exports.setEqual = setEqual;
exports.listEqual = listEqual;
exports.dictEqual = dictEqual;
exports.SP = ' ';
exports.range = range;
exports.exists = exists;
