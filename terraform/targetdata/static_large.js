const getTargets=async ()=>{

    let longList=[
        "domain1.com",
        "domain2.com"
      ]

      let longListData=longList.map((i)=>{
          return {
              name: i,
              domain: i
          }
      })
    return longListData
}
