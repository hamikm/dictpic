function arrayEqual(first, second) {
  if (first.length !== second.length) {
    return false;
  }

  for (let i = 0; i < second.length; i += 1) {
    if (!first.includes(second[i])) {
      return false;
    }
  }

  return true;
}

function arraySubset(first, second) {
  for (let i = 0; i < second.length; i += 1) {
    if (!first.includes(second[i])) {
      return false;
    }
  }
  return true;
}

/**
 * Chunks e.g. [1, 2, 3, 4, 5] into [[1, 2], [3, 4], [5]]
 */
const chunk = (collection, size) => {
  const result = [];
  size = size || 2;
  for (let x = 0; x < Math.ceil(collection.length / size); x += 1) {
    const start = x * size;
    const end = start + size;
    result.push(collection.slice(start, end));
  }
  return result;
};

/**
 * Flattens array to given depth. E.g., ([1, [2, [3, [4, [5]]]]], 2) flattens into
 * [1, 2, 3, [4, [5]]]
 */
const flatten = (lst, depth) => {
  const flattenAux = (_lst, d, _depth) => _lst.reduce((acc, item) => {
    if (Array.isArray(item) && d < _depth) {
      return acc.concat(flattenAux(item, d + 1, _depth));
    }
    return acc.concat(item);
  }, []);

  depth = (typeof depth === 'number') ? depth : Infinity;
  if (!depth) {
    if (Array.isArray(lst)) {
      return lst.map(i => i);
    }
    return lst;
  }
  return flattenAux(lst, 1, depth);
};

exports.arrayEqual = arrayEqual;
exports.arraySubset = arraySubset;
exports.chunk = chunk;
exports.flatten = flatten;
