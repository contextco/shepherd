export function scrollableParent(element) {
  const style = getComputedStyle(element);
  if (style.position === "fixed") {
    return document.body;
  }

  const excludeStaticParent = style.position === "absolute";
  const overflowRegex = /(auto|scroll)/;

  for (let parent = element; (parent = parent.parentElement); ) {
    const parentStyle = getComputedStyle(parent);
    if (excludeStaticParent && parentStyle.position === "static") {
      continue;
    }
    if (
      overflowRegex.test(
        parentStyle.overflow + parentStyle.overflowY + parentStyle.overflowX,
      )
    ) {
      return parent;
    }
  }

  return document.body;
}
